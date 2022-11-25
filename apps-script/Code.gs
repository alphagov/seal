/**
 * @OnlyCurrentDoc
 */

function onOpen() {
  var spreadsheet = SpreadsheetApp.getActive();
  var menuItems = [
    {name: 'Refresh Repos tab', functionName: 'updateRepos'},
  ];
  spreadsheet.addMenu('Update Data', menuItems);
}

function updateRepos(){
  var csvUrl = "https://docs.publishing.service.gov.uk/repos.csv";
  var csvContent = UrlFetchApp.fetch(csvUrl).getContentText();
  var csvData = Utilities.parseCsv(csvContent);

  var sheet = SpreadsheetApp.getActive().getSheetByName('Repos');
  sheet.clear({ contentsOnly: true });
  sheet.getRange(1, 1, csvData.length, csvData[0].length).setValues(csvData);
  sheet.deleteColumns(3, (csvData[0].length - 2));
  updateSheet_(sheet);
}

function updateSheet_(sheet) {
  updateHeaders_(sheet);
  endRow = sheet.getLastRow();
  for (var r = 2; r <= endRow; r++) {
    updateRow_(sheet.getRange(r, 1, 1, 5));
  }
}

function updateHeaders_(sheet) {
  sheet.getRange(1, 3).setValue("Ruby");
  sheet.getRange(1, 4).setValue("Rails");
  sheet.getRange(1, 5).setValue("Mongoid");
  sheet.getRange(1, 6).setValue("Sidekiq");
  sheet.getRange(1, 7).setValue("Schema");
  sheet.getRange(1, 8).setValue("Slimmer");
  sheet.getRange(1, 9).setValue("govuk_publishing_components");
  sheet.getRange(1, 10).setValue("activesupport");
  sheet.getRange(1, 11).setValue("activerecord");
  sheet.getRange(1, 12).setValue("Gem?");
}

function updateRow_(row) {
  var repo = row.getValue();
  if (repo != '') {
    updateRubyVersion_(repo,    row.offset(0,2,1,1));
    updateRailsVersion_(repo,   row.offset(0,3,1,1));
    updateMongoidVersion_(repo, row.offset(0,4,1,1));
    updateSidekiqVersion_(repo,    row.offset(0,5,1,1));
    updateSchemasVersion_(repo,    row.offset(0,6,1,1));
    updateSlimmerVersion_(repo,    row.offset(0,7,1,1));
    updateComponentVersion_(repo,    row.offset(0,8,1,1));
    updateActiveSupportVersion_(repo,    row.offset(0,9,1,1));
    updateActiveRecordVersion_(repo,    row.offset(0,10,1,1));
    updateRepoType(repo,    row.offset(0,11,1,1));
  }
}

function updateRubyVersion_(repo, targetCell) {
  var url = "https://raw.githubusercontent.com/alphagov/" + repo + "/main/.ruby-version";
  var version = getFileContents_(url);
  if (version) {
    targetCell.setValue(version);
  } else {
    targetCell.setValue("unspecified");
  }    
}

function updateRailsVersion_(repo, targetCell) {
  if (repo == 'errbit') {
    updateErrbitRailsVersion_(repo, targetCell);
    return;
  }

  if (repo == 'bouncer') {
    updateBouncerRailsVersion_(repo, targetCell);
    return;
  }
  
  var version = getVersionFromGemfileLock_(repo, 'rails');
  if (version === undefined) {
    version = getVersionFromGemfile_(repo, 'rails');
  }
  if (version == undefined) {
    version = '';
  }
  targetCell.setValue(version);
}

// Mongoid may be specified implicitly as a dependency (e.g. by using
// govuk_content_models, so we check Gemfile.lock, not Gemfile
function updateMongoidVersion_(repo, targetCell) {
  var version = getVersionFromGemfileLock_(repo, 'mongoid');
  if (version === undefined) {
    version = getVersionFromGemfile_(repo, 'mongoid');
  }
  targetCell.setValue(version);
}

// Errbit doesn't depend on all of Rails, it only depends on actionpack,
// actionmailer and railties. We therefore pull the pinned version of one
// of these from Gemfile.lock
function updateErrbitRailsVersion_(repo, targetCell) {
  var version = getVersionFromGemfileLock_(repo, 'actionpack');
  if (version === undefined) {
    version = '';
  }
  targetCell.setValue(version);
}

// Bouncer doesn't depend on Rails, but it does use ActiveRecord so we 
// pull the pinned version of that from Gemfile.lock
function updateBouncerRailsVersion_(repo, targetCell) {
  var version = getVersionFromGemfileLock_(repo, 'activerecord');
  if (version === undefined) {
    version = '';
  }
  targetCell.setValue(version);
}

function updateSidekiqVersion_(repo, targetCell) {
  var version = getVersionFromGemfileLock_(repo, 'sidekiq');
  if (version === undefined) {
    version = '';
  }
  targetCell.setValue(version);
}


function updateSchemasVersion_(repo, targetCell) {
  var version = getVersionFromGemfileLock_(repo, 'govuk_schemas');
  if (version === undefined) {
    version = '';
  }
  targetCell.setValue(version);
}

function updateSlimmerVersion_(repo, targetCell) {
  var version = getVersionFromGemfileLock_(repo, 'slimmer');
  if (version === undefined) {
    version = '';
  }
  targetCell.setValue(version);
}

function updateComponentVersion_(repo, targetCell) {
  var version = getVersionFromGemfileLock_(repo, 'govuk_publishing_components');
  if (version === undefined) {
    version = '';
  }
  targetCell.setValue(version);
}

function updateActiveSupportVersion_(repo, targetCell) {
  var version = getVersionFromGemfileLock_(repo, 'activesupport');
  if (version === undefined) {
    version = '';
  }
  targetCell.setValue(version);
}

function updateActiveRecordVersion_(repo, targetCell) {
  var version = getVersionFromGemfileLock_(repo, 'activerecord');
  if (version === undefined) {
    version = '';
  }
  targetCell.setValue(version);
}

function getVersionFromGemfileLock_(repo, dependencyName) {
  var gemfileLock = getFileContents_("https://raw.githubusercontent.com/alphagov/" + repo + "/master/Gemfile.lock");
  if (!gemfileLock) {
    return undefined;
  }
  var matches = gemfileLock.match(new RegExp("\n    "+dependencyName+"\\s+\\(([\\d.]+)\\)"));
  if (matches) {
      if (matches[1] === undefined) {
        return "unable to fetch version from Gemfile.lock";
      } else {
        return matches[1];
      }
  } else {
    return "n/a";
  }
}

function getVersionFromGemfile_(repo, dependencyName) {
  var gemfile = getFileContents_("https://raw.githubusercontent.com/alphagov/" + repo + "/master/Gemfile");
  if (!gemfile) {
    return undefined;
  } else {
    var matches = gemfile.match(new RegExp("gem\\s+['\"]"+dependencyName+"['\"], ['\"](.*?)['\"]"));
    if (matches) {
      if (matches[1] === undefined) {
        return "Unable to fetch version from Gemfile";
      } else {
        return matches[1];
      }
    } else {
      if (gemfile.match(/\ngemspec/)) {
        return getVersionFromGemspec_(repo, dependencyName);
      } else {
        return "n/a";
      }
    }
  }
}

function getVersionFromGemspec_(repo, dependencyName) {
  var gemspec = getFileContents_("https://raw.githubusercontent.com/alphagov/" + repo + "/master/" + repo + ".gemspec");
  if (!gemspec) {
    return undefined;
  } else {
    var matches = gemspec.match(new RegExp("\""+dependencyName+"\"(?:,\\s+[\"'](.+)[\"'])+"));
    if (matches) {
      if (matches[1] === undefined) {
        return "any version";
      } else {
        return matches[1];
      }
    } else {
      return "n/a";
    }
  }
}

function updateRepoType(repo, targetCell) {
  var gemspec = getFileContents_("https://raw.githubusercontent.com/alphagov/" + repo + "/master/" + repo + ".gemspec");
  if (gemspec) {
    targetCell.setValue("Yes");
  } else {
    targetCell.setValue("No");
  }    
}

function getFileContents_(url) {
  var response = UrlFetchApp.fetch(url, {muteHttpExceptions: true});
  switch(response.getResponseCode()) {
    case 200:
      return response.getContentText().trim();
    case 404:
      return undefined;
    default:
      Logger.log("HTTP code: %d, body: %s", response.getResponseCode(), response.getContentText())
      return undefined;
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                               											 //
// This scraper needs to be run on with the google script plugin: 							 //
// https://script.google.com/a/g.rit.edu/d/11ai1l7bTP9WSO1KUPJO9r-AacScs-u0W0UUPKjCNSQCO2VcI82kACR9a/edit?usp=drive_web  //
//  															 //
// It will update the 'Sheriff Calendar' file in the google drive. It will execute as your current Google user, so you   // 
// have to have the calendars added to the account. If you don't want to run this on your personal Google account, we    //
// have a team account you can use.   							                                 //
//  															 //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//modified code from http://blog.ouseful.info/2010/03/05/grabbing-google-calendar-event-details-into-a-spreadsheet/
//some referenced APIs:
  //http://www.google.com/google-d-s/scripts/class_calendar.html#getEvents
  //http://www.google.com/google-d-s/scripts/class_calendarevent.html
  //https://developers.google.com/apps-script/reference/spreadsheet/sheet
  //https://developers.google.com/apps-script/reference/spreadsheet/spreadsheet-app
//to get a spreadsheet ID, see http://stackoverflow.com/questions/12990637/accessing-spreadsheet-in-google-script/12990713#12990713
function calendarScraper(){
  //this maps to Sheriff Calendar in the Google Drive
  var sheet = SpreadsheetApp.openById("1p4P8IT2RMTgGxRkzdHhvUe5wywgv589I4uBg3s43FGw").getActiveSheet();
  
  var calendarNames = ["Chrome Build Sheriff Rotation","Chrome GPU Pixel Wrangling","Chromium Perf Sheriff Rotation",
                       "Chrome Valgrind Sheriff","Chromium Troopers Rotation"]; //note: the troopers contains both early and normal trooper events
  
  //insert a header row in the spreadsheet
  sheet.getRange(1,1,1,5).setValues([["Event Name","Start Date","End Date", "Duration", "Attendee Emails"]]);
  var spreadsheetIndex = 2;
  
  //iterate through calendars
  for(calIndex=0;calIndex<calendarNames.length;calIndex++){
    var cal = CalendarApp.openByName(calendarNames[calIndex]);
    var events = cal.getEvents(new Date("January 1, 2008"), new Date("August 31, 2014"));
    
    //iterate through events and add to spreadsheet
    for (var i=1;i<events.length;i++) {
      var guests = events[i].getGuestList();
      var guestEmails = [];
      
      //get all guest emails to put in spreadsheet
      for(var j=0;j<guests.length;j++){
        var duration = (events[i].getEndTime() - events[i].getStartTime()) / 3600000
        //build details to put in spreadsheet
        var details=[[calendarNames[calIndex], events[i].getStartTime(), events[i].getEndTime(), duration, guests[j].getEmail()]];
      
        //propagate data to spreadsheet
        var spreadsheetIndex=spreadsheetIndex+1;
        var range=sheet.getRange(spreadsheetIndex,1,1,5);
        range.setValues(details);
      }
    }
  }
}

/**** ************************************************ ****/
/**** Initialize and maintain system time/date display ****/
/**** ************************************************ ****/
$(function () {

    displayTimeElement = $("#system-time");
    if (displayTimeElement.length > 0) updateDisplayedTime();

    displayDateElement = $("#system-date");
    if (displayDateElement.length > 0) updateDisplayedDate();

});
var referenceDate = null;
var displayDateElement = null;
var displayTimeElement = null;
var dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
var monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

function updateDisplayedTime() {
    var now = new Date();
    var hour = now.getHours();
    var minute = now.getMinutes();
    var am_pm = (hour > 11 ? "PM" : "AM");
    if (hour > 12) hour -= 12;
    else if (hour == 0) hour = 12;
    displayTimeElement.html((hour < 10 ? "0" : "") + hour + ":" + (minute < 10 ? "0" : "") + minute + " " + am_pm);

    // Set execution for the next new minute. Keeps our time updated to the system time, w/i 1 second. 1 second added to avoid possible execution/system time sync issues.
    setTimeout(updateDisplayedTime, (61 - now.getSeconds()) * 1000);
}

function updateDisplayedDate() {
    var now = new Date();

    // If we've reached a date different than what we started we'll need to update the MDY displayed
    if (referenceDate == null || referenceDate.getDay() != now.getDay()) {
        referenceDate = new Date();

        displayDateElement.html(dayNames[referenceDate.getDay()] + ", " + monthNames[referenceDate.getMonth()] + " " + (referenceDate.getDate() < 10 ? "0" : "") 
                                + referenceDate.getDate() + ", " + referenceDate.getFullYear()); 
    }

    // Set execution for the next new day. Keeps our date updated to the system date, w/i 1 second. 1 second added to avoid possible execution/system time sync issues.
    var nextTime = Date.parse((referenceDate.getMonth() + 1) + "/" + (referenceDate.getDate() + 1) + "/" + referenceDate.getFullYear()) - referenceDate.getTime() + 1000;
    setTimeout(updateDisplayedDate, nextTime);
}
/**** ********************* ****/
/****   Handle tab clicks   ****/
/**** ********************* ****/
$("div#navDiv a").click(function (e) {
    e.preventDefault();
    e.stopPropagation();
    console.log("clicked a tab");
    var $theForm = $("form#tabNav");
    $theForm.children("input#category").prop("value", $(this).prop("id"));
    $theForm.children("input#year").prop("value", "<%= year %>"); // this won't work because it's not a .inc page
    if($(this).parent().hasClass('active')){
        $theForm.submit();
    }
});



$(function() {
    console.log("Loading Students...");

    function loadStudents() {
            $.getJSON("/api/student/", function( students ) {
                    console.log(students);
                    var message = "Nobody is here";
                    if( students.length > 0) {
                            message = students[0].animal + " " + students[0].lastname;
                    }
                    $(".white-text").text(message);
            });
    };

    loadStudents();
    setInterval( loadStudents, 2000);
});
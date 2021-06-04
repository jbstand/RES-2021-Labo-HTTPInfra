$(function() {
    console.log("Loading Students...");

    function loadStudents() {
            $.getJSON("/api/student/", function( students ) {
                    console.log(students);
                    var message = "Nobody is here";
                    if( students.length > 0) {
                            message = "Animal : " + students[0].animal + ", Profession : " + students[0].profession;
                    }
                    $(".white-text").text(message);
            });
    };

    loadStudents();
    setInterval( loadStudents, 2000);
});
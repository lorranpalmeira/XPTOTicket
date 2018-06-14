/// <reference path="jquery-1.9.1.intellisense.js" />
//Load Data in Table when documents is ready
$(document).ready(function () {
    loadData();

    

    $("#UserName").on('focusout', function () {

        var name = $("#UserName").val();
        var status = $('#spanUserName');
        var user = $.trim(name);
        status.html('Checking ...');

        if (user.length > 4) {
            $.ajax({
                type: 'POST',
                url: '/Account/ValidateUserName',
                dataType: 'json',
                data: { UserName: user },
                success: function (data) {
                    if (data === true) {
                        status.html("<font color=red>'<b>" + name + "</b>' is not available!</font>");
                    } else {
                        status.html("<font color=green>'<b>" + name + "</b>' is available!</font>");
                        var nameRegex = /^[a-zA-Z_.-]*$/;
                        if (!nameRegex.test(name)) {
                            status.html("<font color=red>'<b>" + name + "</b>' is Invalid!</font>");
                        }
                        console.log("Sucess");
                    }
                },
                error: function (error) {
                    console.log("Logging Error" + error);
                }
            });
        } else {
            status.html("Need more characters...");
        }

        return false;
    })



   
   
});

//Load Data function
function loadData() {
    $.ajax({
        url: "/Account/ListUsers",
        type: "GET",
        contentType: "application/json;charset=utf-8",
        dataType: "json",
        success: function (result) {
            var html = '';
            $.each(result, function (key, item) {
                html += '<tr>';
                html += '<td>' + item.UserName + '</td>';
                html += '<td>' + item.Email + '</td>';
                html += '<td>' + item.CompanyId + '</td>';
                html += '<td>' + item.RoleName + '</td>';
                html += '<td><a href="#" onclick="return getbyID(' + item.UserName + ')">Edit</a> | <a href="#" onclick="Delele(' + item.UserName + ')">Delete</a></td>';
                html += '</tr>';
            });
            $('.tbody').html(html);

        },
        error: function (errormessage) {
            console.log("deu erro para carregar os dados " + errormessage);
            alert(errormessage.responseText);
        }
    });
}

/*
function add_anti_forgery_token(data) {
    data.__RequestVerificationToken = $('[name=__RequestVerificationToken]').val();
    return data;
}
*/
function addRequestVerificationToken(data) {
    data.__RequestVerificationToken = $('input[name=__RequestVerificationToken]').val();
    return data;
};


//Add Data Function 
function Add() {
    var res = validate();
    if (res == false) {
        return false;
    }
    var empObj = {
        
        UserName: $('#UserName').val(),
        Email: $('#Email').val(),
        Password: $('#Password').val(),
        ConfirmPassword: $('#ConfirmPassword').val(),
        CompanyId: $('#CompanyId').val(),
        RoleName: $('#RoleName').val()
    };
    $.ajax({
        url: "/Account/Register",
        //data: JSON.stringify(addRequestVerificationToken(empObj)),
        data: JSON.stringify(empObj),
        type: "POST",
        contentType: "application/json;charset=utf-8",
        dataType: "json",
        success: function (result) {
            
            loadData();

            $('#myModal').modal('hide');
            $('body').removeClass('modal-open');
            $('.modal-backdrop').remove();
           
        },
        error: function (errormessage) {
            alert(errormessage.responseText);
            console.log("Deu Erro");
        }
    });
}


//Function for getting the Data Based upon Employee ID
function getbyID(UserName) {
    $('#UserName').css('border-color', 'lightgrey');
    $('#Email').css('border-color', 'lightgrey');
    $('#CompanyId').css('border-color', 'lightgrey');
    $('#RoleName').css('border-color', 'lightgrey');
     $.ajax({
         url: "/Account/GetbyID/" + UserName,
        typr: "GET",
        contentType: "application/json;charset=UTF-8",
        dataType: "json",
        success: function (result) {
            
            $('#UserName').val(result.UserName);
            $('#Email').val(result.Email);
            $('#CompanyId').val(result.CompanyId);
            $('#RoleName').val(result.RoleName);
            

            $('#myModal').modal('show');
            $('#btnUpdate').show();
            $('#btnAdd').hide();
        },
        error: function (errormessage) {
            alert(errormessage.responseText);
        }
    });
    return false;
}

//function for updating employee's record
function Update() {
    var res = validate();
    if (res == false) {
        return false;
    }
    var empObj = {
        
        UserName: $('#UserName').val(),
        Email: $('#Email').val(),
        Password: $('#Password').val(),
        ConfirmPassword: $('#ConfirmPassword').val(),
        CompanyId: $('#CompanyId').val(),
        RoleName: $('#RoleName').val(),
        
    };
    $.ajax({
        url: "/Account/Update",
        data: JSON.stringify(add_anti_forgery_token(empObj)),
        type: "POST",
        contentType: "application/json;charset=utf-8",
        dataType: "json",
        success: function (result) {
            loadData();
            $('#myModal').modal('hide');
            $('#Id').val("");
            $('#UserName').val("");
            $('#Email').val("");
            $('#Password').val("");
            $('#ConfirmPassword').val("");
            $('#CompanyId').val("");
            $('#RoleName').val("");
        },
        error: function (errormessage) {
            alert(errormessage.responseText);
        }
    });
}



function Delele(UserName) {

    bootbox.confirm({
        message: "Remove User?",
        buttons: {
            confirm: {
                label: 'Yes',
                className: 'btn-danger'
            },
            cancel: {
                label: 'No',
                className: 'btn-success'
            }
        },
        callback: function (result) {
            if (result) {
                $.ajax({
                    url: "/Account/Delete/" + UserName,
                    type: "POST",
                    contentType: "application/json;charset=UTF-8",
                    dataType: "json",
                    success: function (result) {
                        loadData();
                    },
                    error: function (errormessage) {
                        alert(errormessage.responseText);
                    }
                });
            }
            console.log('This was logged in the callback: ' + result);
        }
    });


}


//Function for clearing the textboxes
function clearTextBox() {
    $('#UserName').val("");
    $('#spanUserName').val("");
    $('#Email').val("");
    $('#PassWord').val("");
    $('#ConfirmPassword').val("");
    $('#CompanyId').val("");
    $('#RoleName').val("");
    $('#btnUpdate').hide();
    $('#btnAdd').show();
    $('#UserName').css('border-color', 'lightgrey');
    $('#Email').css('border-color', 'lightgrey');
    $('#PassWord').css('border-color', 'lightgrey');
    $('#CompanyId').css('border-color', 'lightgrey');
    $('#RoleName').css('border-color', 'lightgrey');


}
//Valdidation using jquery
function validate() {
    var isValid = true;
    if ($('#UserName').val().trim() == "") {
        $('#UserName').css('border-color', 'Red');
        isValid = false;
    }
    else {
        $('#UserName').css('border-color', 'lightgrey');
    }
    if ($('#Password').val().trim() == "") {
        $('#Password').css('border-color', 'Red');
        isValid = false;
    }
    else {
        $('#Password').css('border-color', 'lightgrey');
    }
    
    if ($('#RoleName').val().trim() == "") {
        $('#RoleName').css('border-color', 'Red');
        isValid = false;
    }
    else {
        $('#RoleName').css('border-color', 'lightgrey');
    }
    
    if ($('#Email').val().trim() == "") {
        $('#Email').css('border-color', 'Red');
        isValid = false;
    }
    else {
        $('#Email').css('border-color', 'lightgrey');
    }
    
    if ($('#CompanyId').val().trim() == "") {
        $('#CompanyId').css('border-color', 'Red');
        isValid = false;
    }
    else {
        $('#CompanyId').css('border-color', 'lightgrey');
    }
    
    return isValid;
}






/*


*/

/*
  $("#UserName").focusout(function () {
        var name = $("#UserName").val(); //Value entered in the text box
        var status = $("#spanUserName"); //span object to display the status message
        var user = $.trim(name);
        if (user.length > 4) {
            status.html("Checking....") //While our Thread works, we will show some message to indicate the progress
            //jQuery AJAX Post request
            $.post("/Account/ValidateUserName", { username: name },
               
                function (data) {
                    if (data != true) {
                        status.html("<font color=green>'<b>" + name + "</b>' is available!</font>");
                    } else {
                        status.html("<font color=red>'<b>" + name + "</b>' is not available!</font>");
                    }
                });
        } else {
            status.html("Need more characters...");
        }
    });
*/
/// <reference path="jquery-1.9.1.intellisense.js" />
//Load Data in Table when documents is ready
$(document).ready(function () {
    loadData();
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
                html += '<td>' + item.Id + '</td>';
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
            console.log("deu erro para careegar os dados " + errormessage);
            alert(errormessage.responseText);
        }
    });
}

function add_anti_forgery_token(data) {
    data.__RequestVerificationToken = $('[name=__RequestVerificationToken]').val();
    return data;
}

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
        data: JSON.stringify(add_anti_forgery_token(empObj)),
        type: "POST",
        contentType: "application/json;charset=utf-8",
        dataType: "json",
        success: function (result) {
            console.log("Antes do Loader");
            loadData();
            console.log("Depois Loader Antes fechar modal");
            $('#myModal').modal('hide');
            $('body').removeClass('modal-open');
            $('.modal-backdrop').remove();
            console.log("Depois de fechar modal");
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



function Delele(ID) {

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
                    url: "/Login/Delete/" + ID,
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
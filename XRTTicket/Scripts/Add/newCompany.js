/// <reference path="jquery-1.9.1.intellisense.js" />
//Load Data in Table when documents is ready
$(document).ready(function () {
    loadData();
});

//Load Data function
function loadData() {
    $.ajax({
        url: "/Company/CompanyListJson",
        type: "GET",
        contentType: "application/json;charset=utf-8",
        dataType: "json",
        success: function (result) {
            var html = '';
            var line = 0;
            $.each(result, function (key, item) {

                line++;
                if (line <= quantMaxByPage)
                {
                    html += '<tr>';
                    html += '<td>' + item.CompanyId + '</td>';
                    html += '<td>' + item.CompanyName + '</td>';
                    html += '<td>' + item.Grade + '</td>';
                    html += '<td>' + item.Flag + '</td>';
                    html += '<td>' + item.Phone + '</td>';
                    html += '<td><a href="#" onclick="return getbyID(' + item.CompanyId + ')">Edit</a> | <a href="#" onclick="Delele(' + item.CompanyId + ')">Delete</a></td>';
                    html += '</tr>';
                }
            });
            $('.tbody').html(html);

        },
        error: function (errormessage) {
            console.log("deu erro para carregar os dados " + errormessage);
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
        
        CompanyName: $('#CompanyName').val(),
        Grade: $('#Grade').val(),
        Flag: $('#Flag').val(),
        Phone: $('#Phone').val(),

    };
    $.ajax({
        url: "/Company/Add",
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
            
        }
    });
}


//Function for getting the Data Based upon Employee ID
function getbyID(id) {
    
    $('#CompanyName').css('border-color', 'lightgrey');
    $('#Grade').css('border-color', 'lightgrey');
    $('#Flag').css('border-color', 'lightgrey');
    $('#Phone').css('border-color', 'lightgrey');
     $.ajax({
         url: "/Company/GetbyID/" + id,
        typr: "GET",
        contentType: "application/json;charset=UTF-8",
        dataType: "json",
        success: function (result) {
            $('#CompanyId').val(result.CompanyId);
            $('#CompanyName').val(result.CompanyName);
            $('#Grade').val(result.Grade);
            $('#Flag').val(result.Flag);
            $('#Phone').val(result.Phone);
            

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
        CompanyId: $('#CompanyId').val(),
        CompanyName: $('#CompanyName').val(),
        Grade: $('#Grade').val(),
        Flag: $('#Flag').val(),
        Phone: $('#Phone').val()
    };
    $.ajax({
        url: "/Company/Update",
        data: JSON.stringify(add_anti_forgery_token(empObj)),
        type: "POST",
        contentType: "application/json;charset=utf-8",
        dataType: "json",
        success: function (result) {
            loadData();
            $('#myModal').modal('hide');
            $('#CompanyId').val("");
            $('#CompanyName').val("");
            $('#Grade').val("");
            $('#Flag').val("");
            $('#Phone').val("");
           
        },
        error: function (errormessage) {
            alert(errormessage.responseText);
        }
    });
}



function Delele(id) {

    bootbox.confirm({
        message: "Remove this Company?",
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
                    url: "/Company/Delete/" + id,
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
    $('#CompanyName').val("");
    $('#Grade').val("");
    $('#Flag').val("");
    $('#Phone').val("");
    $('#btnUpdate').hide();
    $('#btnAdd').show();
    $('#CompanyName').css('border-color', 'lightgrey');
    $('#Grade').css('border-color', 'lightgrey');
    $('#Flag').css('border-color', 'lightgrey');
    $('#Phone').css('border-color', 'lightgrey');
    
}
//Valdidation using jquery
function validate() {
    var isValid = true;
    if ($('#CompanyName').val().trim() == "") {
        $('#CompanyName').css('border-color', 'Red');
        isValid = false;
    }
    else {
        $('#CompanyName').css('border-color', 'lightgrey');
    }
    if ($('#Flag').val().trim() == "") {
        $('#Flag').css('border-color', 'Red');
        isValid = false;
    }
    else {
        $('#Flag').css('border-color', 'lightgrey');
    }
    
    if ($('#Phone').val().trim() == "") {
        $('#Phone').css('border-color', 'Red');
        isValid = false;
    }
    else {
        $('#Phone').css('border-color', 'lightgrey');
    }
    
   
    
    return isValid;
}
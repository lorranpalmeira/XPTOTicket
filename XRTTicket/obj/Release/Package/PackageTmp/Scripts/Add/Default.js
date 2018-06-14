
$(document).ready(function () {
    loadData();
});


//ANTI FORGERY
function add_anti_forgery_token(data) {
    data.__RequestVerificationToken = $('[name=__RequestVerificationToken]').val();
    return data;
}

// ADD
function Add(empObj) {
    var res = validate();
    if (res == false) {
        return false;
    }
    /*
    var empObj = {

        CompanyName: $('#CompanyName').val(),
        Grade: $('#Grade').val(),
        Flag: $('#Flag').val(),
        Phone: $('#Phone').val(),

    };
    */
    $.ajax({
        url: urlAdd,
        //data: JSON.stringify(addRequestVerificationToken(empObj)),
        data: JSON.stringify(empObj),
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

        }
    });
}


//DELETE
function Delele(id) {

    bootbox.confirm({
        message: "Remove it?",
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
                    //url: "/Company/Delete/" + id,
                    url: urlDelete +"/"+ id,
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

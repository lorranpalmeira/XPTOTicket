

$('#file').fileupload({
    dataType: 'json',
    data: $('#TicketId').val(),
    url: '/Ticket/UploadFiles',
    autoUpload: true,
    done: function (e, data) {
      
    }
}).on('fileuploadprogressall', function (e, data) {
    
});





$('#download_file').click(function (e) {
        e.preventDefault();
        $.ajax({
            type: 'GET',
            url: 'Ticket/DownloadFile',
            dataType: 'json',
            data: { path: $("#downloadLabel").val() },
            success: function (data) {
                alert("Done");
               // $("#iframe").attr("src", "/Ticket/DownloadFile?path=" + path);
            },
            error: function (ex) {
                alert('Download fail. ' + ex);
            }
        });
    });

$(document).ready(function () {

 


    textAreaSize();

    // Fields

    $("#StatusId").change(function () {
        ValidateRequired("#StatusId", "#div-status", "#message-status");
        ValidateFilledFields();
    })

    //----------------------------------------

    // Functions

    function add_anti_forgery_token(data) {
        data.__RequestVerificationToken = $('[name=__RequestVerificationToken]').val();
        return data;
    }

    // Function resize textarea
    
    function textAreaSize() {

        $("textarea").each(function () {
            var letter = $(this).val().length;
            if (letter > 200) {
                $(this).attr('rows', '8');
            } else {
                $(this).attr('rows', '2');
            }
        });

        // Increse size field description
        $("#field-description").attr('rows', '8');

    }

    function appendElement(data) {
        //Create element by Jquery
        
        publicVariable = '';

        var newElement =
            $('<div class="form-group" id="div-new-element-' + data.actions.IterationId + '">' +
                '<label>By ' + data.actions.AlteredBy + ' - ' + moment(data.actions.Date).fromNow() + '</label>' +
                '<textarea readonly class="form-control" id="new-element-' + data.actions.IterationId + '">' +
                    data.actions.ActionDescription+
                '</textarea>' +
                publicVariable +
                /*
                ' <label for="sendtouser">Public</label>' +
                */
            '</div>');
        $("#div-iterations").prepend(newElement);     // Append new elements
        $("#field-description").val(''); // Clear field description
        textAreaSize(); // check textareasize
        
    }

    function changeElements(data) {
        $('#TicketTypeId option[value=' + data.ticket.TicketTypeId + ']').attr('selected', 'selected');
        $('#PriorityId option[value=' + data.ticket.PriorityId + ']').attr('selected', 'selected');

    }
   
    
    // Trim TextArea
    $("textarea").each(function () { $(this).val($(this).val().trim()); });

    


    
    

    
    // Add TextArea Element Async
    $('#btn-submit').click(function (event) {
        event.preventDefault();
       
        var Ticket = {  
            TicketId: $('#ticketId').val(),
            TicketTypeId: $('#TicketTypeId').val(),
            PriorityId: $('#PriorityId').val(),
            ProductId: $('#ProductId').val(),
            SubProductId: $('#SubProductId').val(),
            TaskId: $('#TaskId').val(),
            VersionId: $('#VersionId').val(),
            StatusId: $('#StatusId').val(),
            SlaExpiration: $('#SlaExpiration').val(),
            AnalystDesignated: $('#UserId').val(),
            Title: $('#field-title').val(),
            Description: $('#field-description').val(),
            SendToUser: $('#sendtouser').is(':checked'),
            
            DuplicatedOf: $('#field-duplicate').val(),
            IdExternal: $('#field-IdExternal').val()
        };  
        $.ajax({  
            type: "POST",  
            url: AsyncTextArea,
            data: JSON.stringify(add_anti_forgery_token(Ticket)),
            dataType: "json"  ,
            contentType: 'application/json; charset=utf-8',  
        success: function(data) {  
            // Prepend Element
            appendElement(data);
            changeElements(data);
            $('#message-description').removeClass('glyphicon glyphicon-ok icon-success');
            $('#btn-submit').attr('disabled', 'true');

            toastr["success"]("Ticket updated with success", "Update")

            toastr.options = {
                "closeButton": false,
                "debug": false,
                "newestOnTop": false,
                "progressBar": false,
                "positionClass": "toast-bottom-right",
                "preventDuplicates": true,
                "onclick": null,
                "showDuration": "300",
                "hideDuration": "1000",
                "timeOut": "3000",
                "extendedTimeOut": "1000",
                "showEasing": "swing",
                "hideEasing": "linear",
                "showMethod": "fadeIn",
                "hideMethod": "fadeOut"
            }


        },  
        error: function() {  
            alert("Error occured!!")  
        }  
    });  
});






})
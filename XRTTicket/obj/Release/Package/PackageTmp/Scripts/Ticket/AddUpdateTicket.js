$( document ).ready(function() {

    //-----------------Get Ticket Id ----------------------------
    if (isNewTicket) {
        document.getElementById("ticketId").value = ticketId;
    } else {

        ValidateRequired("#ProductId", "#div-product", "#message-product");
        ValidateRequired("#TicketTypeId", "#div-tickettype", "#message-tickettype");
        ValidateRequired("#SubProductId", "#div-subproduct", "#message-subproduct");
        ValidateRequired("#TaskId", "#div-task", "#message-task");
        ValidateRequired("#VersionId", "#div-version", "#message-version");
        ValidateRequired("#StatusId", "#div-status", "#message-status");
        ValidateRequired("#PriorityId", "#div-priority", "#message-priority");
        ValidateRequired("#StatusId", "#div-status", "#message-status");
        ValidateSizeField('#div-title', '#field-title', '#message-title', 5);
        //ValidateSizeField('#div-description', '#field-description', '#message-description', 10);
        ValidateFilledFields();
       
    }
    

    //Campo Id estilizado
    ValidateRequired("#ticketId","#div-id","#message-id");

    //----------------------------------------------------------------

    $("#ProductId").change(function () {
        ValidateRequired("#ProductId", "#div-product", "#message-product");
        $("#VersionId").empty();
        $("#VersionId").append('<option value="0">[Select a Version..]</option>');
        $.ajax({
            type: 'POST',
            url: urlGetVersion,
            dataType: 'json',
            data: { productId: $("#ProductId").val() },
            success: function (data) {
                $.each(data, function (i, data) {
                    $("#VersionId").append('<option value="'
                     + data.VersionId + '">'
                     + data.VersionName + '</option>');
                });
                ValidateFilledFields();
            },
            error: function (ex) {
                alert('Fail to find item.' + ex);
            }
        });
       
        ValidateRequired("#VersionId", "#div-version", "#message-version");
        return false;
    })


    // -----------------------------------------------------------------
    $("#ProductId").change(function () {
        ValidateRequired("#ProductId", "#div-product", "#message-product");

        $("#SubProductId").empty();
               
        $("#TaskId").empty();
        $("#SubProductId").append('<option value="0">[Select an item..]</option>');
        $.ajax({
            type: 'POST',
            url: urlGetSubProducts,
            dataType: 'json',
            data: { productId: $("#ProductId").val() },
            success: function (data) {
                $.each(data, function (i, data) {
                    $("#SubProductId").append('<option value="'
                     + data.SubProductId + '">'
                     + data.Name + '</option>');
                });
                ValidateFilledFields();
            },
            error: function (ex) {
                alert('Fail to find item.' + ex);
            }
        });
        ValidateRequired("#SubProductId", "#div-subproduct", "#message-subproduct");
        ValidateRequired("#TaskId", "#div-task", "#message-task");
        return false;
    })

    //----------------------------------------------------------------
    $("#SubProductId").change(function () {
        ValidateRequired("#SubProductId", "#div-subproduct", "#message-subproduct");

        $("#TaskId").empty();
        $("#TaskId").append('<option value="0">[Select an item..]</option>');
        $.ajax({
            type: 'POST',
            url:urlGetTask,
            dataType: 'json',
            data: { productId: $("#ProductId").val() ,
                subproductId: $("#SubProductId").val()
            },
            success: function (data) {
                $.each(data, function (i, data) {
                    $("#TaskId").append('<option value="'
                     + data.TaskId + '">'
                     + data.Name + '</option>');
                });
                ValidateFilledFields();
            },
            error: function (ex) {
                alert('Fail to find item.' + ex);
            }
        });
        ValidateRequired("#TaskId", "#div-task", "#message-task");
        return false;
    })
    //----------------------------------------------------------------


    //------------------

    $("#TaskId").change(function(){
        ValidateRequired("#TaskId","#div-task","#message-task");
        ValidateFilledFields();
    })
    //----------------------------------------------------------------
    $("#VersionId").change(function(){
        ValidateRequired("#VersionId","#div-version","#message-version");
        ValidateFilledFields();
    })
    //----------------------------------------------------------------

    $("#PriorityId").change(function(){
        ValidateRequired("#PriorityId","#div-priority","#message-priority");
        ValidateFilledFields();
    })
    //----------------------------------------------------------------------
    $("#TicketTypeId").change(function(){
        ValidateRequired("#TicketTypeId","#div-tickettype","#message-tickettype");
        ValidateFilledFields();
    })
    //----------------------------------------------------------------

    

    // Field Title
    $("#div-title").on("input focusout",function () {

        //Remove class error or sucess to Default/ DIV and Message
        clearToDefault('#div-title','#message-title');

        ValidateSizeField('#div-title','#field-title','#message-title',5);

        ValidateFilledFields();
                

    })

    // Field Description
    $("#div-description").on("input focusout",function () {

        //Remove class error or sucess to Default/ DIV and Message
        clearToDefault('#div-description','#message-description');

        ValidateSizeField('#div-description','#field-description','#message-description',10);

        ValidateFilledFields();

    })

    //---------------Functions----------------------------------------

    // Refactory 
    

    function clearToDefault(div,message){
        $(div).removeClass('form-group has-success').addClass('form-group');
        $(div).removeClass('form-group has-error').addClass('form-group');
        $(message).removeClass();
        $(message).html('');
    }


    function ValidateRequired(field, div, message){
        var produtoId = $(field).val();
        if(produtoId > 0){
                        
            $(message).addClass('glyphicon glyphicon-ok icon-success');
            $(div).removeClass('col-xs-3').addClass('col-xs-3 has-success');
                        
        }else{
            $(div).removeClass('col-xs-3 has-success').addClass('col-xs-3');
            $(message).removeClass('glyphicon glyphicon-ok icon-success');
                       
        }
    }

    function ValidateSizeField(div,field,message,size){
        let fieldSize = $(field).val().length ;

        if(fieldSize < size){
            $(div).removeClass('form-group').addClass('form-group has-error');
            $(message).html('Minimium of '+size+' caracters.');
            $(message).addClass('fail');

        }else
        {
            $(div).removeClass('form-group').addClass('form-group has-success');
            $(message).addClass('glyphicon glyphicon-ok icon-success');
                    
        }
    }

           
    function ValidateFilledFields(){
        var fail=0;
        var filledFields = {
            messageversion: $('#message-version').attr('class'),
            messagepriority: $('#message-priority').attr('class'),
            messagetickettype: $('#message-tickettype').attr('class'),
            messageproduct: $('#message-product').attr('class'),
            messagesubproduct: $('#message-subproduct').attr('class'),
            messagetask: $('#message-task').attr('class'),
            messagetitle: $('#message-title').attr('class'),
            messagedescription: $('#message-description').attr('class')
        };

        $.each(filledFields, function(index, value) {
                    
            if(value != 'glyphicon glyphicon-ok icon-success'){
                fail = fail+1;
            }
                    
        });

        if(fail ==0){
            $('#btn-submit').attr('disabled',false);
        }else{
            $('#btn-submit').attr('disabled',true);
        }


    }

    //----------------------- End Functions --------------------------
});

function appendElement(data) {
    

    var newElement =
        $(  '<tr>' +
                '<td><a href="/Ticket/TicketUpdate/'+data.TicketId+'" >' + data.TicketId + '</a></td>' +
                '<td>' + data.Title + '</td>' +
            '</tr>'
         );

    $("#tableIsLike").append(newElement);     
  
  
}


$("#IsLike").ready(function () {

    $.ajax({
        type: 'POST',
        url: isLikeAjax,
        dataType: 'json',
        data: { title: $("#field-title").val(), ticketId: $("#ticketId").val() },
        success: function (data) {
            $.each(data, function (i, data) {
                $("#isLike").show();
                appendElement(data);
            });
            
        },
        error: function (ex) {
            alert('Fail to find item.' + ex);
        }
    });
});

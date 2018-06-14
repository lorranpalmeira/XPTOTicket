
function add_anti_forgery_token(data) {
    data.__RequestVerificationToken = $('[name=__RequestVerificationToken]').val();
    return data;
}




var quantityPage = 10;
var quant = quantPage * quantityPage;
var totalRecords = quantPage % quantityPage > 0 ? quant++ : quant;
var size = 5;

$('.page-item-next').on('click', function (e) {

    if (itemjs => 6) {
        $('.page-item-previous').show();
    }


    itemjs = itemjs < 1 ? itemjs = 5 : itemjs;

    if (quantPage > itemjs && itemjs > 1) {

        itemjs = parseInt(itemjs) + parseInt(1);
        $('.page-item').remove();

        var total = quantPage < size + itemjs ? quantPage : size + itemjs;

        for (var i = itemjs; i <= total ; i++) {

            $('<li class="page-item">' +
                  '<a class="page-link" href="#">' + i + '</a>' +
                  '<input id="hidden" type="hidden" value="' + i + '">' +
                '</li>').insertBefore(".page-item-next");
            itemjs = i;
        }

    }

    if (itemjs >= quantPage) {
        $('.page-item-next').hide();
    }

});


$('.page-item-previous').on('click', function () {

    if (itemjs <= quantPage) {
        $('.page-item-next').show();
    }

    if (itemjs > 5) {

        var pagination = $('.page-item').length;


        $('.page-item').remove();

        itemjs = parseInt(itemjs) - parseInt(pagination);

        var total = quantPage < size + itemjs ? quantPage : size + itemjs;

        for (var i = itemjs; i >= 1 ; i--) {

            $('<li class="page-item">' +
                         '<a class="page-link" href="#">' + i + '</a>' +
                         '<input id="hidden" type="hidden" value="' + i + '">' +
                     '</li>').insertAfter(".page-item-previous");

            itemjs = -i;
        }

    }

    if (itemjs <= 5) {
        $('.page-item-previous').hide();
    }


});





$(document).ready(function () {

    // Hide class
    $('.page-item-previous').hide();

   

    $(document).on('click', '.page-item', function () {
        var btn = $(this),
            sizePage = 10; //$('#ddl_tam_pag').val(),
        page = btn.text(),
        url =url,
        param = { 'page': page, 'sizePage': sizePage };


        $.post(url, add_anti_forgery_token(param), function (response) {
            if (response) {
                var table = $('#table').find('tbody');

                table.empty();
                for (var i = 0; i < response.length; i++) {
                    var ticket = response[i].TicketId;
                    var jsDateOpenDateAndTime = moment(response[i].OpenDateAndTime).toDate();
                    var jsDateSlaExpiration = moment(response[i].SlaExpiration).toDate();

                    if (url === '/Company/GetAllCompaniesPagination') {
                        table.append(
                        '<tr>' +
                        '<td>' + response[i].CompanyId + '</td>' +
                        '<td>' + response[i].CompanyName + '</td>' +
                        '<td>' + response[i].Grade + '</td>' +
                        '<td>' + response[i].Flag + '</td>' +
                        '<td>' + response[i].Phone + '</td>' +
                     
                        '</tr>');
                    }else{
                        table.append(
                        '<tr>' +
                        '<td><a href="/Ticket/TicketUpdate/' + ticket + '">' + ticket + '</a></td>' +
                        '<td>' + response[i].Title + '</td>' +
                        '<td>' + response[i].PriorityId + '</td>' +
                        '<td>' + jsDateOpenDateAndTime.toLocaleString() + '</td>' +
                        '<td>' + jsDateSlaExpiration.toLocaleString() + '</td>' +
                        '</tr>');
                    }
                }

                btn.siblings().removeClass('active');
                btn.addClass('active');
            }


        });





    })

})

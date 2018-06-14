
using Xunit;

namespace XRTTicket.Test.Controllers.Test.Ticket
{
    public class Ticket
    {

        private readonly XRTTicket.Controllers.Ticket.TicketController _ticket;

        public Ticket()
        {
            _ticket = new XRTTicket.Controllers.Ticket.TicketController();
        }

        [Fact]
        public void IsLikeAjaxTest() {

            var result = _ticket.LikeTicketAjax("teste",-1);
            Assert.NotEqual(result, null);
        }
    }
}

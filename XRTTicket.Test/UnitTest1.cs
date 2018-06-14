
using Xunit;

namespace XRTTicket.Test
{
   
    public class UnitTest1
    {
        private readonly DAO.TicketDao _ticket;

        public UnitTest1() {
            _ticket = new DAO.TicketDao();
        }



        [Fact]
        public void TestMethod1()
        {
            var result = _ticket.Next();

            Assert.Equal( result, 1 );

        }

        [Fact]
        public void TestMethod2()
        {
            var result = _ticket.Next();
            
            Assert.NotEqual(result, 0);

        }

        

    }
}

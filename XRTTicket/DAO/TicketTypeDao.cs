using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using XRTTicket.Contexts;
using XRTTicket.Models.Ticket;

namespace XRTTicket.DAO
{
    public class TicketTypeDao : BaseContext<TicketType>, IUnitOfWork<TicketType>
    {

        public int Next() => DbSet.Max(x => x.TicketTypeId) + 1;
    }
}
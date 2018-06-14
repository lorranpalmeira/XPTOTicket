using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using XRTTicket.Contexts;
using XRTTicket.Models.Ticket;

namespace XRTTicket.DAO
{
    public class StatusDao : BaseContext<Status>, IUnitOfWork<Status>
    {
        public int Next() => DbSet.Max(x => x.StatusId) + 1;
    }
}
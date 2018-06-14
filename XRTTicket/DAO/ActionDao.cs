using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using XRTTicket.Contexts;

namespace XRTTicket.DAO
{
    public class ActionDao : BaseContext<XRTTicket.Models.Ticket.Action>, IUnitOfWork<XRTTicket.Models.Ticket.Action>
    {
        public int Next() {
            var result = 1;// DbSet.Where(x => x.DescriptionId);
                //DbSet.Max(x => x.IterationId) + 1;

            return result;
        }
    }
}
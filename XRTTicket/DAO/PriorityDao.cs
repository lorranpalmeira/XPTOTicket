using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using XRTTicket.Contexts;
using XRTTicket.Models;

namespace XRTTicket.DAO
{
    public class PriorityDao : BaseContext<Priority>, IUnitOfWork<Priority>
    {
        public int Next() => DbSet.Max(x => x.PriorityId ) + 1;
    
    }
}
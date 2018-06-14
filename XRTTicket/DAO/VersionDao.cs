
using System.Linq;

using XRTTicket.Contexts;
using XRTTicket.Models.Ticket;

namespace XRTTicket.DAO
{
    public class VersionDao : BaseContext<Version>, IUnitOfWork<Version>
    {
        public int Next() => DbSet.Max(x => x.VersionId) + 1;
    }
}
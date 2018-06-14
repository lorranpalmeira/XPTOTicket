using System.Linq;
using XRTTicket.Contexts;
using XRTTicket.Models.Companies;
using XRTTicket.Models.Ticket;

namespace XRTTicket.DAO
{
    public class CompanyDao : BaseContext<Company>, IUnitOfWork<Company>
    {
            public int Next() => DbSet.Max(x => x.CompanyId) + 1;
    }
}
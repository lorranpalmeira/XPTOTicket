using System;
using XRTTicket.Contexts;
using XRTTicket.Models;

namespace XRTTicket.Controllers
{
    internal class RoleDao : BaseContext<Role>, IUnitOfWork<Role>
    {
        public int Next()
        {
            throw new NotImplementedException();
        }
    }
}
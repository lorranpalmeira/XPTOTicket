using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using XRTTicket.Contexts;

namespace XRTTicket.DAO
{
    public class RegisterViewModelDao : BaseContext<Models.RegisterViewModel>, IUnitOfWork<Models.RegisterViewModel>
    {

        public int Next()
        {
            var result = 1;// DbSet.Where(x => x.DescriptionId);
                           //DbSet.Max(x => x.IterationId) + 1;

            return result;
        }
    }
}
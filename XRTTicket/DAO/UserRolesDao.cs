using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using XRTTicket.Contexts;
using XRTTicket.Models;

namespace XRTTicket.DAO
{
    

    public class UserRolesDao : BaseContext<UserRoles>, IUnitOfWork<UserRoles>
    {
        public int Next()
        {
            throw new NotImplementedException();
        }

        public int Save(UserRoles role ) {

            
            Database.ExecuteSqlCommand("INSERT INTO AspNetUserRoles VALUES(@UserId,@Role)",
                                        new SqlParameter("UserId", role.UserId),
                                        new SqlParameter("Role", role.RoleId));
            
            
            return SaveChanges();
        }
    }
}
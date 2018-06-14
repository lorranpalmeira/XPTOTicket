using Microsoft.AspNet.Identity;
using System.Security.Claims;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using XRTTicket.ClassesHelper;
using XRTTicket.Models;

namespace XRTTicket.BusinessModel
{
    public class Permissions
    {
        // HttpContext.Current.User.Identity.GetUserId()  
        public static List<Priority> PriorityUser() {
                        
                if (!HttpContext.Current.User.IsInRole("User"))
                {
                    return Repository._priority;
            }
                else {
                    return Repository._priority.Where(x => x.PriorityId != 1 ).ToList();
            }
            

            
        }
        
    }
}
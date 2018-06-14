using Microsoft.AspNet.Identity;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using XRTTicket.Contexts;
using XRTTicket.DAO;
using XRTTicket.Models.Ticket;

namespace XRTTicket.ClassesHelper
{
    public class ListToPagination
    {

        IUnitOfWork<ViewModelTicket> UnitOfTicket { get; set; }
        IUnitOfWork<Models.Ticket.Action> UnitOfTicketAction { get; set; }
        public ListToPagination()
        {
            this.UnitOfTicket = new TicketDao();
            this.UnitOfTicketAction = new ActionDao();
        }


        public List<ViewModelTicket> ListItens() {
            var ticketClosedValid = Repository._status.Where(x => x.StatusId == 04).Select(x => x.StatusId).FirstOrDefault();
            var ticketClosedInValid = Repository._status.Where(x => x.StatusId == 05).Select(x => x.StatusId).FirstOrDefault();
            return UnitOfTicket.Where(x => x.StatusId != ticketClosedValid
            && x.StatusId != ticketClosedInValid
            && x.AnalystDesignated == null
            ).ToList();

        }

        
        /*
        public List<ViewModelTicket> ListItensSeachTicket(ViewModelTicket ticket,
            DateTime? opendatefrom, DateTime? opendateto, string description) {

            
            var query = UnitOfTicket.Where(x => x.ProductId > 0);
            if (opendatefrom != null && opendateto != null)
            {
                query = query.Where(c => c.OpenDateAndTime >= opendatefrom && c.OpenDateAndTime <= opendateto);
            }
            if (!string.IsNullOrEmpty(ticket.Title))
            {
                query = query.Where(c => c.Title.Contains(ticket.Title));
            }
            if (ticket.TicketId > 0)
            {
                query = query.Where(c => c.TicketId == ticket.TicketId);
            }
            if (ticket.StatusId > 0)
            {
                query = query.Where(c => c.StatusId == ticket.StatusId);
            }
            if (ticket.IdExternal > 0)
            {
                query = query.Where(c => c.IdExternal == ticket.IdExternal);
            }
            if (ticket.TicketTypeId > 0)
            {
                query = query.Where(c => c.TicketTypeId == ticket.TicketTypeId);
            }
            if (ticket.CompanyId > 0)
            {
                query = query.Where(c => c.CompanyId == ticket.CompanyId);
            }
            if (ticket.PriorityId > 0)
            {
                query = query.Where(c => c.PriorityId == ticket.PriorityId);
            }
            if (!string.IsNullOrEmpty(description))
            {
                query = query.Where(c => c.Title.Contains(ticket.Title));
            }
            if (!string.IsNullOrEmpty(ticket.UserId))
            {
                query = query.Where(c => c.UserId == ticket.UserId);
            }
            if (!string.IsNullOrEmpty(ticket.AnalystDesignated))
            {
                query = query.Where(c => c.AnalystDesignated == ticket.AnalystDesignated);
            }
            if (User.IsInRole("User"))
            {
                query = query.Where(c => c.UserId == User.Identity.GetUserName());
            }
            if (User.IsInRole("SuperUser"))
            {
                var user = (System.Security.Claims.ClaimsIdentity)User.Identity;
                var companyId = Convert.ToInt32(user.FindFirstValue("CompanyId"));
                query = query.Where(x => x.CompanyId == companyId);
            }


            var list = query.ToList();

            return list;

        }

            */

    }
}
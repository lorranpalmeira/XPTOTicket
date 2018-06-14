using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Data.Entity.Infrastructure;
using System.Linq;
using System.Web;
using XRTTicket.Contexts;
using XRTTicket.DAO;
using XRTTicket.Models.Ticket;

namespace XRTTicket.DAO
{
    public class TicketDao : BaseContext<ViewModelTicket> , IUnitOfWork<ViewModelTicket>
    {
        public int Next()
        {

            var result = 0;
            try
            {
                result = DbSet.Max(x => x.TicketId) + 1;
            }
            catch (Exception e)
            {
                 result = 1;
            }
            
            return result;


        }


        public int Update(ViewModelTicket model , int id)
        {


            var excluded = new[] { "OpenDateAndTime", "UserId","CompanyId" };
            
            
            var entry = this.Entry(model);
            if (entry.State == EntityState.Detached)
                this.DbSet.Attach(model);

            this.ChangeObjectState(model, EntityState.Modified);
            foreach (var name in excluded)
            {
                entry.Property(name).IsModified = false;
            }

            return this.SaveChanges();
            
        }

       


        /*
        private readonly Context _context = new Context();

        public TicketDao()
        {
        }
        
        public TicketDao(Contexts.Context _context)
        {
            this._context = _context;
        }
        


        public void Add(ViewModelTicket ticket)
        {

            using (var context = new Contexts.Context())
            {
                context.Ticket.Add(ticket);
                context.SaveChanges();
            }
        }

        public IList<ViewModelTicket> List()
        {
            using (var context = new Contexts.Context())
            {
                return context.Ticket.ToList();
            }
        }


        public int Max() {
        {
            using (var context = new Contexts.Context())
            {
               return context.Ticket.Max(x => x.TicketId) +1;
            }
        }
        }


        public void Dispose()
        {
            _context.Dispose();
        }

        public ViewModelTicket GetById(int ticketId)
        {
            using (var context = new Contexts.Context())
            {
                return context.Ticket.FirstOrDefault(x => x.TicketId == ticketId);
            }
        }

        public ViewModelTicket Update(ViewModelTicket ticket)
        {
            using (var context = new Contexts.Context())
            {
                var entity = context.Ticket.Find(ticket.TicketId);
                context.Entry(entity).CurrentValues.SetValues(ticket);
                context.SaveChanges();

                return entity;


            }
        }
        */
    }
}
using System;
using System.Collections.Generic;
using System.Data.Entity.ModelConfiguration;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using XRTTicket.Models.Ticket;

namespace XRTTicket.Contexts
{
    public interface IMapping
    {
    }

    public class TicketMapping : EntityTypeConfiguration<ViewModelTicket>, IMapping
    {

        public TicketMapping()
        {
            this.ToTable("Ticket");
            this.HasKey(x => x.TicketId);
            this.Property(x => x.OpenDateAndTime);
            this.Property(x => x.ClosedDateTime);
            this.Property(x => x.Title).IsRequired().HasMaxLength(50);
            this.Property(x => x.VersionId).IsRequired();
            this.Property(x => x.PriorityId).IsRequired();
            this.Property(x => x.ProductId).IsRequired();
            this.Property(x => x.SubProductId).IsRequired();
            this.Property(x => x.TaskId).IsRequired();
            this.Property(x => x.TicketTypeId).IsRequired();
            this.Property(x => x.StatusId).IsRequired();
            this.Property(x => x.CompanyId );
            this.Property(x => x.SlaExpiration);
            

            //this.HasMany(x => x.Recipes).WithOptional().HasForeignKey(x => x.UserId);
        }

    }


}

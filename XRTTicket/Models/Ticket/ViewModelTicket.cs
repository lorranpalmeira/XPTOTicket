using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace XRTTicket.Models.Ticket
{
    [Table("Ticket")]
    public class ViewModelTicket
    {

        [Key]
        public int TicketId { get; set; }
        public DateTime OpenDateAndTime { get; set; }
        public DateTime? ClosedDateTime { get; set; }

        [Required]
        //[ForeignKey("Version")]
        //public virtual ICollection<Version> Version { get; set; }
        public int VersionId { get; set; }

        [Required]
        //[ForeignKey("Priority")]
        //public virtual ICollection<Priority> Priority { get; set; }
        public int PriorityId { get; set; }

        //[ForeignKey("Company")]
        //public virtual ICollection<Company> Company { get; set; }
        public int CompanyId { get; set; }

        public int? IdExternal { get; set; } 

        public string UserId { get; set; }

        
        public string AnalystDesignated { get; set; }

        public int? Rate { get; set; }
        
        public DateTime SlaExpiration { get; set; }

        public string Environment { get; set; }

        public string Impact { get; set; }

        [Required]
       // [ForeignKey("TicketType")]
        //public virtual ICollection<TicketType> TicketType { get; set; }
        public int TicketTypeId { get; set; }

        public int? DuplicatedOf { get; set; }

        [Required]
        //[ForeignKey("Status")]
        //public virtual ICollection<Status> Status { get; set; }
        public int StatusId { get; set; }


        [Required]
        //[ForeignKey("Product")]
        //public virtual ICollection<Product> Product { get; set; }
        public int ProductId { get; set; }

        [Required]
        //[ForeignKey("SubProduct")]
        //public virtual ICollection<SubProduct> SubProduct { get; set; }
        public int SubProductId { get; set; }

        [Required]
        //[ForeignKey("Task")]
        //public virtual ICollection<Task> Task { get; set; }
        public int TaskId { get; set; }


        [MinLength(5), MaxLength(100), Required]
        public string Title { get; set; }

        //[MinLength(10), Required]
        //public int DescriptionId { get; set; }
        

        

    }
}
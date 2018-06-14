using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace XRTTicket.Models.Ticket
{

    
    public class Action
    {

        //[DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Key]
        public int Id { get; set; }

        public int TicketId { get; set; }
                
        public int IterationId { get; set; }

        public string ActionDescription { get; set; }

        public int StatusId { get; set; }

        public int PriorityId { get; set; }

        public TimeSpan SlaRest { get; set; }

        public DateTime Date { get; set; }

        public string AlteredBy { get; set; }

        public bool SendToUser { get; set; }

        public string Files { get; set; }

    }
}
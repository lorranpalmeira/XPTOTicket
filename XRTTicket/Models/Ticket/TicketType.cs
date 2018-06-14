using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace XRTTicket.Models.Ticket
{
    public class TicketType
    {

        [Key]
        public int TicketTypeId { get; set; }
        public string TicketTypeName { get; set; }
    }
}
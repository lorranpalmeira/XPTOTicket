using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace XRTTicket.Models.Ticket
{
    public class Version
    {
        
        public int ProductId { get; internal set; }
        [Key]
        public int VersionId { get; set; }
        public string VersionName { get; set; }

     
    }
}
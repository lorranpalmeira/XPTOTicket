using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace XRTTicket.Models
{
    public class Priority
    {
        [Key]
        public int PriorityId { get; set; }
        public string PriorityLevel { get; set; }
        public int SlaTime { get; set; }
        public bool WorkDays { get; set; }

        
    }
}
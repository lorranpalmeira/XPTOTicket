using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace XRTTicket.Models.Companies
{
    public class Company
    {

        [Key]
        public int CompanyId { get; set; }
        public string CompanyName { get; set; }

        public string FullName { get; set; }

        public int? Grade { get; set; }

        public string Flag { get; set; }

        public string Phone { get; set; }

        public bool Blocked { get; set; }

    }
}
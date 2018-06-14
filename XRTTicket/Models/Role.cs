using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Web;

namespace XRTTicket.Models
{
    [Table("AspNetRoles")]
    public class Role
    {
        
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public string Id { get; set; }
        
        //[DatabaseGenerated(DatabaseGeneratedOption.None)]
        public string Name { get; set; }
    }
}
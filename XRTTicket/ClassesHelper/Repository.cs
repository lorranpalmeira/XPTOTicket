using Microsoft.ApplicationInsights.Extensibility.Implementation;
using Microsoft.AspNet.Identity;
using Microsoft.AspNet.Identity.EntityFramework;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.ModelBinding;
using XRTTicket.Models;
using XRTTicket.Models.Ticket;

namespace XRTTicket.ClassesHelper
{
    public class Repository
    {

        #region DataBaseTemporary
        public static List<XRTTicket.Models.Ticket.ViewModelTicket> _list = new List<XRTTicket.Models.Ticket.ViewModelTicket> {
            new Models.Ticket.ViewModelTicket  { TicketId=02, PriorityId=1,Title="Chamado 2", ProductId=01,SubProductId=01,TaskId=01,VersionId=142,OpenDateAndTime= DateTime.Now.ToLocalTime(),SlaExpiration=DateTime.Now.ToLocalTime() },
            new Models.Ticket.ViewModelTicket  { TicketId=03, PriorityId=1,Title="Chamado 3", ProductId=01,SubProductId=01,TaskId=01,VersionId=142,OpenDateAndTime= DateTime.Now.ToLocalTime(),SlaExpiration=DateTime.Now.ToLocalTime() },
            new Models.Ticket.ViewModelTicket  { TicketId=04, PriorityId=2,Title="Chamado 4", ProductId=02,SubProductId=02,TaskId=01,VersionId=115,OpenDateAndTime= DateTime.Now.ToLocalTime(),SlaExpiration=DateTime.Now.ToLocalTime() },
            new Models.Ticket.ViewModelTicket  { TicketId=05, PriorityId=4,Title="Chamado 5", ProductId=02,SubProductId=02,TaskId=01,VersionId=115,OpenDateAndTime= DateTime.Now.ToLocalTime(),SlaExpiration=DateTime.Now.ToLocalTime() },
            new Models.Ticket.ViewModelTicket  { TicketId=06, PriorityId=1,Title="Chamado 6", ProductId=01,SubProductId=01,TaskId=01,VersionId=142,OpenDateAndTime= DateTime.Now.ToLocalTime(),SlaExpiration=DateTime.Now.ToLocalTime() }
       };

        public static List<Models.Ticket.Product> _product_list = new List<Models.Ticket.Product> {
            new Models.Ticket.Product { ProductId=00, Name="Selecione um Produto" },
            new Models.Ticket.Product { ProductId=01, Name="Universe Web" },
            new Models.Ticket.Product { ProductId=02, Name="Universe 32Bits" }
        };

        public static List<Role> _roles = new List<Role> {
            new Role { Id="User", Name="User" },
            new Role { Id="SuperUser", Name="SuperUser" },
            new Role { Id="Analyst", Name="Analyst" },
            new Role { Id="SuperAnalyst", Name="SuperAnalyst" },
            new Role { Id="ADM", Name="ADM" }
        };


        public static List<Models.Companies.Company> company = new List<Models.Companies.Company> {
            new Models.Companies.Company { CompanyId=00, CompanyName="Selecione uma Companhia" },
            new Models.Companies.Company { CompanyId=01, CompanyName="Vale" },
            new Models.Companies.Company { CompanyId=02, CompanyName="StatKraft" }
        };

        public static List<Models.Ticket.SubProduct> _subproduct_list = new List<Models.Ticket.SubProduct> {
            new Models.Ticket.SubProduct {ProductId=01, SubProductId=01, Name="Elementos Comuns" },
            new Models.Ticket.SubProduct {ProductId=01, SubProductId=02, Name="Tesouraria" },
            new Models.Ticket.SubProduct {ProductId=01, SubProductId=03, Name="Operações Financeiras" },
            new Models.Ticket.SubProduct {ProductId=01, SubProductId=04, Name="Relatórios" },

            new Models.Ticket.SubProduct { ProductId=02, SubProductId=01, Name="Elementos Comuns 32" },
            new Models.Ticket.SubProduct { ProductId=02, SubProductId=02, Name="Tesouraria 32" },
            new Models.Ticket.SubProduct { ProductId=02, SubProductId=03, Name="Operações Financeiras 32" },
            new Models.Ticket.SubProduct { ProductId=02, SubProductId=04, Name="Relatórios 32" }
        };

        public static List<Models.Ticket.Task> _task = new List<Models.Ticket.Task> {
            new Models.Ticket.Task {ProductId=01, SubProductId=01, TaskId=01, Name="Cadastro" },
            new Models.Ticket.Task {ProductId=01, SubProductId=02, TaskId=01, Name="Pagamentos" },
            new Models.Ticket.Task {ProductId=01, SubProductId=03, TaskId=01, Name="Aplicações" },
            new Models.Ticket.Task {ProductId=01, SubProductId=04, TaskId=01, Name="Relatorios Diversos" },

            new Models.Ticket.Task {ProductId=02, SubProductId=01, TaskId=01, Name="Cadastro 32" },
            new Models.Ticket.Task {ProductId=02, SubProductId=02, TaskId=01, Name="Pagamentos 32" },
            new Models.Ticket.Task {ProductId=02, SubProductId=03, TaskId=01, Name="Aplicações 32" },
            new Models.Ticket.Task {ProductId=02, SubProductId=04, TaskId=01, Name="Relatorios Diversos 32" }
        };

        public static List<Priority> _priority = new List<Priority> {
             new Priority  { PriorityId=00, PriorityLevel ="Selecione Uma prioridade" },
             new Priority { PriorityId=01, PriorityLevel="P1 - High" },
             new Priority { PriorityId=02, PriorityLevel="P2 - Medium" },
             new Priority { PriorityId=03, PriorityLevel="P3 - Low" },
             new Priority { PriorityId=04, PriorityLevel="P4 - Very Low" }
        };

        public static List<Priority> _priorityTime = new List<Priority> {
             new Priority  { PriorityId=00,SlaTime=5 },
             new Priority { PriorityId=01,SlaTime=8 },
             new Priority { PriorityId=02,SlaTime=10 },
             new Priority { PriorityId=03,SlaTime=12 },
             new Priority { PriorityId=04,SlaTime=15 }
        };

        public static List<Status> _status = new List<Status> {
             new Status  { StatusId=00, StatusName ="Selecione Uma prioridade" },
             new Status { StatusId=01, StatusName="New" },
             new Status { StatusId=02, StatusName="In Attendance" },
             new Status { StatusId=03, StatusName="Waiting - Dev" },
             new Status { StatusId=04, StatusName="Waiting Customer" },
             new Status { StatusId=05, StatusName="WC-RI" },
             new Status { StatusId=06, StatusName="Close Valid" },
             new Status { StatusId=07, StatusName="Close Invalid" }
             

        };

        public static List<Models.Ticket.Version> _patchlist = new List<Models.Ticket.Version> {
             //new Models.Ticket.Version {ProductId=00,VersionId=000,VersionName="Selecione uma Versão" },
             new Models.Ticket.Version {ProductId=01,VersionId=139,VersionName="1.39" },
             new Models.Ticket.Version {ProductId=01,VersionId=140,VersionName="1.40" },
             new Models.Ticket.Version {ProductId=01,VersionId=141,VersionName="1.41" },
             new Models.Ticket.Version {ProductId=01,VersionId=142,VersionName="1.42" },
             new Models.Ticket.Version {ProductId=02,VersionId=113,VersionName="1.13" },
             new Models.Ticket.Version {ProductId=02,VersionId=114,VersionName="1.14" },
             new Models.Ticket.Version {ProductId=02,VersionId=115,VersionName="1.15" },
             new Models.Ticket.Version {ProductId=02,VersionId=116,VersionName="1.16" }
        };

        public static List<TicketType> _ticketType = new List<TicketType> {
            new TicketType  { TicketTypeId=00, TicketTypeName ="Selecione Um tipo" },
             new TicketType { TicketTypeId=01, TicketTypeName="Bug" },
             new TicketType { TicketTypeId=02, TicketTypeName="Improviment" },
             new TicketType { TicketTypeId=03, TicketTypeName="Support" },
             new TicketType { TicketTypeId=04, TicketTypeName="Procedure" }
        };

        public static List<ApplicationUser> GetRolesToUsers([Control]string ddlRole)
        {
            var context = new ApplicationDbContext();
            var users =
              context.Users.Where(x => x.Roles.Select(y => y.RoleId).Contains(ddlRole)).ToList();

            return users;
        }

        //Get users
        public static List<ApplicationUser> GetAllUsers() {
            var context = new ApplicationDbContext();

            return context.Users.ToList();
        }


        #endregion
    }
}
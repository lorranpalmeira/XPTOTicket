using Microsoft.AspNet.Identity;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Web.Mvc;
using XRTTicket.ClassesHelper;
using XRTTicket.BusinessModel;
using XRTTicket.Contexts;
using XRTTicket.DAO;
using XRTTicket.Models;
using XRTTicket.Models.Ticket;
using System.Web;
using System.IO;
using XRTTicket.Models.Upload;

namespace XRTTicket.Controllers.Ticket
{
    public class TicketController : Controller
    {
       
        IUnitOfWork<ViewModelTicket> UnitOfTicket { get; set; }
        IUnitOfWork<Models.Ticket.Action> UnitOfTicketAction { get; set; }
        public TicketController() {
            this.UnitOfTicket = new TicketDao();
            this.UnitOfTicketAction = new ActionDao();
        }


        public ActionResult Index() {

            return View();
        }


        #region AddTicket
        [Authorize]
        [HttpGet]
        public ActionResult NewTicket()
        {
            ViewBag.PriorityId = new SelectList(Permissions.PriorityUser(), "PriorityId", "PriorityLevel");
            ViewBag.TicketTypeId = new SelectList(Repository._ticketType, "TicketTypeId", "TicketTypeName");
            ViewBag.ProductId = new SelectList(Repository._product_list, "ProductId", "Name");
            ViewBag.SubProductId = new SelectList(new List<SubProduct>(), "SubProductId", "Name");
            ViewBag.TaskId = new SelectList(new List<Task>(), "TaskId", "Name");
            ViewBag.VersionId = new SelectList(new List<Models.Ticket.Version>(), "VersionId", "VersionName");


            ViewBag.NextTicket =  Convert.ToInt32(UnitOfTicket.Next());

            return View();
            
        }

        

        [Authorize]
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult SaveTicket(Models.Ticket.ViewModelTicket ticket, string description, HttpPostedFileBase file)
        {
            if (ModelState.IsValid)
            {
                ticket.TicketId = Convert.ToInt32(UnitOfTicket.Next());
                ticket.OpenDateAndTime = DateTime.Now.ToLocalTime();
                ticket.UserId = User.Identity.GetUserName();
                var user = (System.Security.Claims.ClaimsIdentity)User.Identity;
                ticket.CompanyId = Convert.ToInt32( user.FindFirstValue("CompanyId"));
                ticket.StatusId = 1;

                
                var ret = Repository._priorityTime.Where(x => x.PriorityId == ticket.PriorityId)
                    .Select(x => x.SlaTime).FirstOrDefault();
                 

                ticket.SlaExpiration = CalculateSla.AddWithinWorkingHours(ticket.OpenDateAndTime, 
                    TimeSpan.FromHours(ret ), 9, 8);

              
                this.UnitOfTicket.Save(ticket);

                // Chech if exists files
                var path = string.Empty;
                if(file != null)
                {
                    path = UploadAndDownload.Upload(file, ticket.TicketId);
                }
               

                var actions = new Models.Ticket.Action
                { TicketId = ticket.TicketId,
                    ActionDescription = description,
                    StatusId = ticket.StatusId,
                    Date = DateTime.Now.ToLocalTime(),
                    AlteredBy = User.Identity.Name,
                    SendToUser = true,
                    SlaRest = TimeSpan.FromHours(
                     Repository._priorityTime
                    .Where(x => x.PriorityId == ticket.PriorityId)
                    .Select(x => x.SlaTime).FirstOrDefault()),
                    Files = path,
                    IterationId = 1
                };

                this.UnitOfTicketAction.Save(actions);

                //return RedirectToAction(nameof(NewTicket));
                if (User.IsInRole("User") || User.IsInRole("SuperUser"))
                {
                    return RedirectToAction(nameof(MyTickets));
                }
                else
                {
                    return RedirectToAction(nameof(TicketList));
                }

            }
            else{
                return View(nameof(NewTicket), ticket);
            }
        }

        [HttpPost]
        public ContentResult UploadFiles(int ticketId)
        {
            var r = new List<UploadFilesResult>();

            foreach (string file in Request.Files)
            {
                HttpPostedFileBase hpf = Request.Files[file] as HttpPostedFileBase;
                if (hpf.ContentLength == 0)
                    continue;

                //"~/App_Data/Uploads/Tickets/"
                //string savedFileName = Path.Combine(Server.MapPath("~/App_Data"), Path.GetFileName(hpf.FileName));
                //string path = "~/App_Data/Uploads/Tickets/"+ticketId.ToString();
                var path = "C:/Users/lorran.palmeira/Source/Repos/XRTTicket/XRTTicket/App_Data/Uploads/Tickets/" + ticketId.ToString();
                //var path = "C:/Users/lorran.palmeira/Downloads/Arquivos/" + ticketId.ToString() +"/";
                if (!Directory.Exists(path))
                    Directory.CreateDirectory(path);
                string savedFileName = Path.Combine(Server.MapPath("~/App_Data/Uploads/Tickets/"+ticketId.ToString()), Path.GetFileName(hpf.FileName));
                hpf.SaveAs(savedFileName);

                var actions = new Models.Ticket.Action
                {
                    TicketId = ticketId,
                    ActionDescription = "Sucess UpLoaded file by " + User.Identity.Name + " " + DateTime.Now.ToLocalTime(), 
                    Date = DateTime.Now.ToLocalTime(),
                    StatusId = UnitOfTicket.Where(x => x.TicketId == ticketId).Select(x => x.StatusId).FirstOrDefault(),
                    PriorityId = UnitOfTicket.Where(x => x.TicketId == ticketId).Select(x => x.PriorityId).FirstOrDefault(),
                    AlteredBy = User.Identity.Name,
                    SendToUser = true,
                    Files = path +"/"+ hpf.FileName,
                    IterationId = UnitOfTicketAction.Where(x => x.TicketId == ticketId).Max(x => x.IterationId) + 1
                };

                UnitOfTicketAction.Save(actions);



                /*
                r.Add(new UploadFilesResult()
                {
                    Name = hpf.FileName,
                    Length = hpf.ContentLength,
                    Type = hpf.ContentType
                });
                */
            }
            return Content("{\"name\":\"" + r[0].Name + "\",\"type\":\"" + r[0].Type + "\",\"size\":\"" + string.Format("{0} bytes", r[0].Length) + "\"}", "application/json");
            //return Json("Sucess",JsonRequestBehavior.AllowGet);
        }



        [Authorize]
        public JsonResult SaveTicketAjaxUpdate(ViewModelTicket ticket, string description, bool SendToUser, HttpPostedFileBase file) {

            var diff = TimeSpan.Zero;
            var diffTime = 0.0;
            var lastStatus = UnitOfTicketAction.Where(x => x.TicketId == ticket.TicketId)
                .OrderByDescending(x => x.IterationId)
                .Select(x => x.StatusId).FirstOrDefault();


            if (ticket.StatusId == 6 || ticket.StatusId == 7
                && lastStatus != 6 && lastStatus != 7)
            {
                ticket.ClosedDateTime = DateTime.Now.ToLocalTime();
            }
            
            else if (ticket.StatusId == 3 || ticket.StatusId == 4 || ticket.StatusId == 5
               && lastStatus != 3 && lastStatus != 4 && lastStatus != 5)
            {

                var sla = new CalculateSla();
                var TotalTime = sla.SlaRestTime(ticket.TicketId);

                var time = CalculateSla.SubtractWithinWorkingHours(DateTime.Now.ToLocalTime(), (int)TotalTime);
                
                ticket.SlaExpiration = CalculateSla.AddWithinWorkingHours(DateTime.Now.ToLocalTime(),TimeSpan.FromHours(time), 9, 8);
               
                
                /*
                var dateTicket = UnitOfTicket.Where(x => x.TicketId == ticket.TicketId)
                   .Select(x => x.SlaExpiration).FirstOrDefault();
                    diffTime = dateTicket.Subtract(DateTime.Now.ToLocalTime()).TotalHours;
                CalculateSla.SubtractWithinWorkingHours(DateTime.Now.ToLocalTime(), (int)diffTime);
                */
                    
                
            }
            
            else if ( ticket.StatusId == 2 && lastStatus ==3
                || lastStatus == 4 || lastStatus == 5) {
                var slaRest = UnitOfTicketAction.Where(x => x.TicketId == ticket.TicketId).OrderByDescending(x => x.IterationId).Select(x => x.SlaRest).FirstOrDefault();
                //diff = slaRest;
                diffTime = slaRest.TotalHours;
                ticket.ClosedDateTime = DateTime.Now.ToLocalTime().Add(slaRest);
            }

            var path = string.Empty;
            if (file != null)
            {
                path = UploadAndDownload.Upload(file, ticket.TicketId);
            }



            //If Ticket exist then Update Ticket
            this.UnitOfTicket.Update(ticket, ticket.TicketId);

            var actions = new Models.Ticket.Action
            {
                TicketId = ticket.TicketId,
                ActionDescription = description,
                StatusId = ticket.StatusId,
                Date = DateTime.Now.ToLocalTime(),
                PriorityId = ticket.PriorityId,
                AlteredBy = User.Identity.Name,
                SendToUser = SendToUser,
                //SlaRest = TimeSpan.FromHours(diffTime),
                IterationId = UnitOfTicketAction.Where(x => x.TicketId == ticket.TicketId).Max(x => x.IterationId) + 1
            };


            if (!string.IsNullOrEmpty(description))
                UnitOfTicketAction.Save(actions);

                        
            return Json(new { actions, ticket }, JsonRequestBehavior.AllowGet );
        }

        #endregion


        #region EditTicket

       
        public JsonResult DownloadFile(string path) {

           
                UploadAndDownload.Download(path);

            return Json(JsonRequestBehavior.AllowGet);
        }
       
       

        [Authorize]
        [Route("TicketUpdate/{id}")]
        public ActionResult TicketUpdate(int id) {
            var ticketId = id;

            var ticketIdResult = this.UnitOfTicket.GetById(ticketId);
            //

            var user = (System.Security.Claims.ClaimsIdentity)User.Identity;
            var company = Convert.ToInt32(user.FindFirstValue("CompanyId"));
            var roleUser = user.FindFirstValue("RoleName");

            var userName = User.Identity.GetUserName();
            
            //
            var subProduct = Repository._subproduct_list.Where(x =>  x.ProductId == ticketIdResult.ProductId);
            var task = Repository._task.Where(x => x.ProductId == ticketIdResult.ProductId && x.SubProductId == ticketIdResult.SubProductId);
            var version = Repository._patchlist.Where(x => x.ProductId == ticketIdResult.ProductId );

            // List All User Role Analyst
            
            ViewBag.PriorityId   = new SelectList(Repository._priority, "PriorityId", "PriorityLevel", ticketIdResult.PriorityId );
            ViewBag.TicketTypeId = new SelectList(Repository._ticketType, "TicketTypeId", "TicketTypeName", ticketIdResult.TicketTypeId);
            ViewBag.ProductId    = new SelectList(Repository._product_list, "ProductId", "Name", ticketIdResult.ProductId);
            ViewBag.SubProductId = new SelectList(subProduct, "SubProductId", "Name", ticketIdResult.SubProductId);
            ViewBag.TaskId       = new SelectList(task, "TaskId", "Name",  ticketIdResult.TaskId);
            ViewBag.VersionId    = new SelectList(version, "VersionId", "VersionName", ticketIdResult.VersionId);
            ViewBag.StatusId     = new SelectList(Repository._status, "StatusId", "StatusName",ticketIdResult.StatusId);
                      
            var listUser = Repository.GetRolesToUsers("Analyst");
            listUser.AddRange(Repository.GetRolesToUsers("SuperAnalyst"));
            
            ViewBag.UserId = new SelectList(listUser, "UserName", "UserName", !string.IsNullOrEmpty(ticketIdResult.AnalystDesignated) ? ticketIdResult.AnalystDesignated : null );

            //List of Iterations

            var iterations = UnitOfTicketAction.Where(x => x.TicketId == ticketId).
                OrderByDescending(x => x.IterationId);
          

            var list = iterations.ToList();

            ViewBag.Iterations = list;

           

            //Check If user has permission to acess TicketUpdate.
            if (ticketIdResult.UserId == user.GetUserName() 
                || User.IsInRole("Analyst") || User.IsInRole("SuperAnalyst")
                || User.IsInRole("User") || User.IsInRole("SuperUser") 
                && ticketIdResult.CompanyId == Convert.ToInt32( user.FindFirstValue("CompanyId")))
            {
                return View(ticketIdResult);
            }

            return View("PageNotFound");
        }


        public JsonResult LikeTicketAjax(string title, int ticketId) {

           var result = UnitOfTicket.Where(x => x.Title.Contains(title) && x.TicketId != ticketId ).Take(4);

            return Json( result, JsonRequestBehavior.AllowGet);
        }


        #endregion


        #region TicketList

        ListToPagination pagination = new ListToPagination();

        

        [Authorize(Roles ="Analyst, SuperAnalyst")]
        public ActionResult TicketList()
        {
            //var list = UnitOfTicket.GetAll().ToList();
            
            var list = pagination.ListItens();

            ViewBag.QuantMaxLinhasPorPagina = 10;
            ViewBag.PaginaAtual = 1;

            //var quant = UnitOfTicket.GetAll().Count();
            var quant = list.Count();
            var difQuantPaginas = (quant % ViewBag.QuantMaxLinhasPorPagina) > 0 ? 1 : 0;
            ViewBag.QuantPages = (quant / ViewBag.QuantMaxLinhasPorPagina) + difQuantPaginas;


            return View(list);
        }



        public JsonResult GetListItens(int page, int sizePage) {

            
            var listItens = pagination.ListItens();

            var result = (((page == 1 ? page = 0 : page-1) * sizePage));
            var list = listItens.Skip(result ==0?result:result-1).Take(sizePage);
            
            return Json(list,JsonRequestBehavior.AllowGet);
        }

        [Authorize(Roles = "Analyst, SuperAnalyst")]
        public ActionResult Queue()
        {
            var userName = User.Identity.GetUserName();
            var ticketClosedValid = Repository._status.Where(x => x.StatusId == 06).Select(x => x.StatusId).FirstOrDefault();
            var ticketClosedInValid = Repository._status.Where(x => x.StatusId == 07).Select(x => x.StatusId).FirstOrDefault();
            var list = UnitOfTicket.Where(x => x.StatusId != ticketClosedValid
            && x.StatusId != ticketClosedInValid && x.AnalystDesignated == userName)
            .ToList();


            ViewBag.QuantMaxLinhasPorPagina = 10;
            ViewBag.PaginaAtual = 1;

            var quant = list.Count();
            var difQuantPaginas = (quant % ViewBag.QuantMaxLinhasPorPagina) > 0 ? 1 : 0;
            ViewBag.QuantPages = (quant / ViewBag.QuantMaxLinhasPorPagina) + difQuantPaginas;

            //var list = UnitOfTicket.GetAll().ToList();
          

            return View(list);
        }


        [Authorize(Roles = "User,SuperUser ")]
        public ActionResult MyTickets()
        {
            //var list = UnitOfTicket.GetAll().ToList();
            var userName = User.Identity.GetUserName();
            var list = UnitOfTicket.Where(x => x.UserId == userName && x.StatusId != 06 && x.StatusId != 07).ToList();


            ViewBag.QuantMaxLinhasPorPagina = 10;
            ViewBag.PaginaAtual = 1;

            var quant = list.Count();
            var difQuantPaginas = (quant % ViewBag.QuantMaxLinhasPorPagina) > 0 ? 1 : 0;
            ViewBag.QuantPages = (quant / ViewBag.QuantMaxLinhasPorPagina) + difQuantPaginas;

            return View(list);
        }

        [Authorize(Roles = "User,SuperUser ")]
        public ActionResult ClosedTickets()
        {
            //var list = UnitOfTicket.GetAll().ToList();
            var userName = User.Identity.GetUserName();
            var list = UnitOfTicket.Where(x => x.UserId == userName && x.StatusId == 06 || x.StatusId == 07).OrderByDescending(x => x.ClosedDateTime).Take(10).ToList();

            ViewBag.QuantMaxLinhasPorPagina = 10;
            ViewBag.PaginaAtual = 1;

            var quant = list.Count();
            var difQuantPaginas = (quant % ViewBag.QuantMaxLinhasPorPagina) > 0 ? 1 : 0;
            ViewBag.QuantPages = (quant / ViewBag.QuantMaxLinhasPorPagina) + difQuantPaginas;

            return View("MyTickets", list);
        }




        [Authorize(Roles ="SuperUser")]
        public ActionResult CompanyTickets()
        {
            //var list = UnitOfTicket.GetAll().ToList();
            var company = UnitOfTicket.Where(x => x.UserId == User.Identity.GetUserName() 
            && x.StatusId != 05 
            && x.StatusId != 06).Select(x => x.CompanyId).FirstOrDefault();

            var list = UnitOfTicket.Where(x => x.CompanyId == company ).ToList();

            return View(list);
        }

        #endregion


        #region SearchTicket
        public ActionResult SearchTicket() {

            var Status = Repository._status.ToList();
            ViewBag.Status = Status;
            var designated = UnitOfTicket.Where(x => x.TicketId == x.TicketId).Select(x => x.AnalystDesignated).ToList();
            ViewBag.Designated = Repository.GetRolesToUsers("Analyst").ToList();
            ViewBag.OpenBy = Repository.GetAllUsers();
            ViewBag.TicketType = Repository._ticketType.ToList();
            ViewBag.Priority = Repository._priority.ToList();
            ViewBag.Company = Repository.company.ToList();

            return View(new List<ViewModelTicket>());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult SearchTicket(ViewModelTicket ticket,
            DateTime? opendatefrom, DateTime? opendateto, DateTime? closedatefrom,
           DateTime? closedateto, string description)
        {

            ViewBag.QuantMaxLinhasPorPagina = 10;
            ViewBag.PaginaAtual = 1;

            var quant = ListItensSeachTicket(ticket, opendatefrom, opendateto, closedatefrom, closedateto, description).Count();
            var difQuantPaginas = (quant % ViewBag.QuantMaxLinhasPorPagina) > 0 ? 1 : 0;
            ViewBag.QuantPages = (quant / ViewBag.QuantMaxLinhasPorPagina) + difQuantPaginas;



            var list = ListItensSeachTicket(ticket, opendatefrom, opendateto, closedatefrom, closedateto, description);
            

            
            return PartialView(@"/Views/Shared/Ticket/_PartialViewSearchTicketList.cshtml", list);
          }


        public List<ViewModelTicket> ListItensSeachTicket  (ViewModelTicket ticket,
           DateTime? opendatefrom, DateTime? opendateto, DateTime? closedatefrom, 
           DateTime? closedateto, string description)
        {
            
            var query = UnitOfTicket.Where(x => x.ProductId > 0);
            if (opendatefrom != null && opendateto != null)
            {
                query = query.Where(c => c.OpenDateAndTime >= opendatefrom 
                && c.OpenDateAndTime.Date.AddHours(23).AddMinutes(59).AddSeconds(59) <= opendateto);
            }
            if (closedatefrom != null && closedateto != null) {
                 
                query = query.Where(c => c.ClosedDateTime >= closedatefrom
               &&  c.ClosedDateTime <= closedateto.Value.AddHours(23).AddMinutes(59).AddSeconds(59));
            }
            if (!string.IsNullOrEmpty(ticket.Title))
            {
                query = query.Where(c => c.Title.Contains(ticket.Title));
            }
            if (ticket.TicketId > 0)
            {
                query = query.Where(c => c.TicketId == ticket.TicketId);
            }
            if (ticket.StatusId > 0)
            {
                query = query.Where(c => c.StatusId == ticket.StatusId);
            }
            if (ticket.IdExternal > 0)
            {
                query = query.Where(c => c.IdExternal == ticket.IdExternal);
            }
            if (ticket.TicketTypeId > 0)
            {
                query = query.Where(c => c.TicketTypeId == ticket.TicketTypeId);
            }
            if (ticket.CompanyId > 0)
            {
                query = query.Where(c => c.CompanyId == ticket.CompanyId);
            }
            if (ticket.PriorityId > 0)
            {
                query = query.Where(c => c.PriorityId == ticket.PriorityId);
            }
            if (!string.IsNullOrEmpty(description))
            {
                query = query.Where(c => c.Title.Contains(ticket.Title));
            }
            if (!string.IsNullOrEmpty(ticket.UserId))
            {
                query = query.Where(c => c.UserId == ticket.UserId);
            }
            if (!string.IsNullOrEmpty(ticket.AnalystDesignated))
            {
                query = query.Where(c => c.AnalystDesignated == ticket.AnalystDesignated);
            }
            if (User.IsInRole("User"))
            {
                query = query.Where(c => c.UserId == User.Identity.GetUserName());
            }
            if (User.IsInRole("SuperUser"))
            {
                var user = (System.Security.Claims.ClaimsIdentity)User.Identity;
                var companyId = Convert.ToInt32(user.FindFirstValue("CompanyId"));
                query = query.Where(x => x.CompanyId == companyId);
            }


            var list = query.ToList();

            return list;

        }



        public JsonResult GetListItensSeachTicket(int page, int sizePage)
        {
            /*
             var listItens = pagination.ListItens();

            var result = (((page == 1 ? page = 0 : page-1) * sizePage));
            var list = listItens.Skip(result ==0?result:result-1).Take(sizePage);
            
            return Json(list,JsonRequestBehavior.AllowGet);
             */


            var ticket = new ViewModelTicket();
            var listItens = ListItensSeachTicket(ticket, null, null,null,null, null);

            var result = (((page == 1 ? page = 0 : page - 1) * sizePage));
            var list = UnitOfTicket.GetAll().Skip(result == 0 ? result : result - 1).Take(sizePage);

            return Json(list, JsonRequestBehavior.AllowGet);
        }




        #endregion


    }
}
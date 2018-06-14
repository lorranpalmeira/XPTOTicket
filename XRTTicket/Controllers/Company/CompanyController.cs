using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using XRTTicket.Contexts;
using XRTTicket.DAO;

namespace XRTTicket.Controllers.Company
{
    public class CompanyController : Controller
    {

        IUnitOfWork<Models.Companies.Company> UnitOfTicket { get; set; }
       
        public CompanyController()
        {
            this.UnitOfTicket = new CompanyDao();
           
        }
        // GET: Company
        public ActionResult CompanyList()
        {
            ViewBag.QuantMaxLinhasPorPagina = 5;
            ViewBag.PaginaAtual = 1;

            var quant = UnitOfTicket.GetAll().Count();
            var difQuantPaginas = (quant % ViewBag.QuantMaxLinhasPorPagina) > 0 ? 1 : 0;
            ViewBag.QuantPages = (quant / ViewBag.QuantMaxLinhasPorPagina) + difQuantPaginas;


            var list = UnitOfTicket.GetAll();

            return View(list);
        }

        public JsonResult CompanyListJson()
        {
            ViewBag.QuantMaxLinhasPorPagina = 5;
            ViewBag.PaginaAtual = 1;

            var quant = UnitOfTicket.GetAll().Count();
            var difQuantPaginas = (quant % ViewBag.QuantMaxLinhasPorPagina) > 0 ? 1 : 0;
            ViewBag.QuantPages = (quant / ViewBag.QuantMaxLinhasPorPagina) + difQuantPaginas;

            
            var list = UnitOfTicket.GetAll();

            return Json(list, JsonRequestBehavior.AllowGet);
        }


        public JsonResult GetAllCompaniesPagination(int page, int sizePage) {

            /*
                         var listItens = pagination.ListItens();

            var result = (((page == 1 ? page = 0 : page-1) * sizePage));
            var list = listItens.Skip(result ==0?result:result-1).Take(sizePage);
            
            return Json(list,JsonRequestBehavior.AllowGet);
             */

            var listItens = UnitOfTicket.GetAll();

            var result = (((page == 1 ? page = 0 : page - 1) * sizePage));
            var list = UnitOfTicket.GetAll().Skip(result == 0 ? result : result - 1).Take(sizePage);

            return Json(list,JsonRequestBehavior.AllowGet);
        }



        public JsonResult Add(Models.Companies.Company company) {

            company.CompanyId = UnitOfTicket.Next();

            UnitOfTicket.Save(company);


            return Json(JsonRequestBehavior.AllowGet);
        }

        public JsonResult Delete(int id) {

            var ret = UnitOfTicket.GetById(id);
            UnitOfTicket.Delete(ret);

            return Json(JsonRequestBehavior.AllowGet );

        }

        //[ValidateAntiForgeryToken]
        [HttpPost]
        public JsonResult Update(Models.Companies.Company company) {

            UnitOfTicket.Update(company, company.CompanyId);

            return Json(JsonRequestBehavior.AllowGet);
        }
        

        public JsonResult GetbyID(int id)
        {
            return Json(UnitOfTicket.GetById(id),JsonRequestBehavior.AllowGet);
        }


    }
}
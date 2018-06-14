using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using XRTTicket.ClassesHelper;

namespace XRTTicket.Controllers.GetAjaxRequest
{
    public class GetAllController : Controller
    {
        #region GetAll


        public JsonResult GetVersion(int productId)
        {

            var _versionlist = Repository._patchlist.Where(x => x.ProductId == productId);

            return Json(_versionlist);
        }
        public JsonResult GetSubProducts(int productId)
        {

            var _subproducts = Repository._subproduct_list.Where(x => x.ProductId == productId);

            return Json(_subproducts);
        }

        public JsonResult GetTask(int productId, int subproductId)
        {
            var _taskList = Repository._task.Where(x => x.SubProductId == subproductId && x.ProductId == productId);

            return Json(_taskList);
        }
        #endregion
    }
}
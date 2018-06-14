using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace XRTTicket.ClassesHelper
{
    public class UploadAndDownload
    {

        public static string Upload(HttpPostedFileBase file, int ticketNumber)
        {
            var message = string.Empty;
            try
            {

                if (file.ContentLength > 0)
                {
                    var _FileName = Path.GetFileName(file.FileName);
                    var fullPath = "C:/Users/lorran.palmeira/Downloads/Arquivos/" + ticketNumber.ToString();
                    // var fullPath = "~/Uploads/Ticket/" + ticketNumber.ToString();  //"~/App_Data"
                    //var fullPath = "~/App_Data/Uploads/Tickets/" + ticketNumber.ToString();
                    if (!Directory.Exists(fullPath))
                        Directory.CreateDirectory(fullPath);
                    

                    var _path = Path.Combine(HttpRuntime.AppDomainAppPath, fullPath, _FileName);
                    file.SaveAs(_path);

                    message = fullPath +"/"+ _FileName;


                }
                

                return message;
            }
            catch
            {
                message = string.Empty;
                //message = "File upload failed!!";
                return message;
            }
        }

        public static void Download(string FilePath)
        {
            var divider = FilePath.LastIndexOf("/");
            String FileName = FilePath.Substring(divider + 1);


            System.Web.HttpResponse response = System.Web.HttpContext.Current.Response;
            response.ClearContent();
            response.Clear();
            response.ContentType = System.Net.Mime.MediaTypeNames.Application.Octet; // "text/plain";
            response.AddHeader("Content-Disposition", "attachment; filename=" + FileName + ";");
            response.TransmitFile(FilePath);
            response.Flush();
            response.End();

        }






    }
}
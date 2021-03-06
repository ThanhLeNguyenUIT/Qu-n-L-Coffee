﻿using QuanLyBanHang.DTO;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace QuanLyBanHang.DAO
{
    public class BillInfoDAO
    {
        private static BillInfoDAO instance;

        public static BillInfoDAO Instance 
        {
            get { if (instance == null) instance = new BillInfoDAO(); return BillInfoDAO.instance; }
            private set { BillInfoDAO.instance = value; } 
        }
        private BillInfoDAO() { }
        public List<BillInfo> GetListBillInfo(int id)
        {
            List<BillInfo> listBillinfo = new List<BillInfo>();
            DataTable data = DataProvider.Instance.ExecuteQuery("SELECT * FROM BILLINFO WHERE ID =" + id);
            foreach  (DataRow item in data.Rows)
            {
                BillInfo info = new BillInfo(item);
                listBillinfo.Add(info);
            }
            return listBillinfo;
        }
        public void InsertBillInfo(int idBill, int idFood, int count)
        {

            DataProvider.Instance.ExecuteNonQuery("USP_INSERTBILLINFO @IDBILL , @IDFOOD , @COUNT ", new object[] { idBill, idFood, count });
        }
        public void DeleteBillInfoByBillId(int id)
        {
            string query = "DELETE FROM BILLINFO WHERE IDBILL = " + id;
            DataProvider.Instance.ExecuteNonQuery(query);
        }
    }
}

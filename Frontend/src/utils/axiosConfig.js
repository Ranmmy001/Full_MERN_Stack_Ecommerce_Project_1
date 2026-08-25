// export const base_url = "http://13.221.137.210:5000/api";
// export const base_url = "http://localhost:5000/api/";

export const base_url = process.env.REACT_APP_API_URL 
  ? `${process.env.REACT_APP_API_URL}/api/` 
  : "http://localhost:5000/api/";

const getTokenFromLocalStorage = localStorage.getItem("customer")
  ? JSON.parse(localStorage.getItem("customer"))
  : null;

export const config = {
  headers: {
    Authorization: `Bearer ${
      getTokenFromLocalStorage !== null ? getTokenFromLocalStorage.token : ""
    }`,
    Accept: "application/json",
  },
};

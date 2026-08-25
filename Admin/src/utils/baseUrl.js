// export const base_url = "http://localhost:5000/api/";

export const base_url = process.env.REACT_APP_API_URL 
  ? `${process.env.REACT_APP_API_URL}/api/` 
  : "http://localhost:5000/api/";
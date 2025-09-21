import { NextFunction, Request, Response } from "express";

// @desc Authenticates user and protects routes

export const verify = (req: Request, res: Response, next: NextFunction) => {
  console.log("Auth Middleware");
  next();
};

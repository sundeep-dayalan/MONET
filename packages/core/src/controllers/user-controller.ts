import { asyncHandler } from "@/middleware/async-middleware";
import { User } from "@/types/interfaces/interfaces.common";
import { ApiError } from "@/utils/ApiError";
import { ApiSuccess } from "@/utils/ApiSucess";
import { NextFunction, Request, Response } from "express";

// @desc     Gets all users from database
// @route    /users
// @method   GET

// ? asyncHandler should be used for every request for easy async handling
export const getUsers = asyncHandler(
  async (req: Request, res: Response, next: NextFunction) => {
    // Example user, get from database
    const user = [{ name: "John Doe" }, { name: "Jaen Doe" }];

    // Return json with success message
    res.status(200).json(new ApiSuccess<User[]>(user, "Success!"));
  },
);

// ? asyncHandler should be used for every request for easy async handling
export const errorUser = asyncHandler(
  async (req: Request, res: Response, next: NextFunction) => {
    // Return json with error message and empty data
    throw new ApiError({}, 500, "Handled by asyncHandler")
  },
);

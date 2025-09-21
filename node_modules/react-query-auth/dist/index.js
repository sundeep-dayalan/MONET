"use strict";
var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// src/index.tsx
var src_exports = {};
__export(src_exports, {
  configureAuth: () => configureAuth
});
module.exports = __toCommonJS(src_exports);
var import_react_query = require("@tanstack/react-query");
var import_react = __toESM(require("react"));
var import_jsx_runtime = require("react/jsx-runtime");
function configureAuth(config) {
  const { userFn, userKey = ["authenticated-user"], loginFn, registerFn, logoutFn } = config;
  const useUser = (options) => (0, import_react_query.useQuery)({
    queryKey: userKey,
    queryFn: userFn,
    ...options
  });
  const useLogin = (options) => {
    const queryClient = (0, import_react_query.useQueryClient)();
    const setUser = import_react.default.useCallback((data) => queryClient.setQueryData(userKey, data), [queryClient]);
    return (0, import_react_query.useMutation)({
      mutationFn: loginFn,
      ...options,
      onSuccess: (user, ...rest) => {
        setUser(user);
        options?.onSuccess?.(user, ...rest);
      }
    });
  };
  const useRegister = (options) => {
    const queryClient = (0, import_react_query.useQueryClient)();
    const setUser = import_react.default.useCallback((data) => queryClient.setQueryData(userKey, data), [queryClient]);
    return (0, import_react_query.useMutation)({
      mutationFn: registerFn,
      ...options,
      onSuccess: (user, ...rest) => {
        setUser(user);
        options?.onSuccess?.(user, ...rest);
      }
    });
  };
  const useLogout = (options) => {
    const queryClient = (0, import_react_query.useQueryClient)();
    const setUser = import_react.default.useCallback((data) => queryClient.setQueryData(userKey, data), [queryClient]);
    return (0, import_react_query.useMutation)({
      mutationFn: logoutFn,
      ...options,
      onSuccess: (...args) => {
        setUser(null);
        options?.onSuccess?.(...args);
      }
    });
  };
  function AuthLoader({
    children,
    renderLoading,
    renderUnauthenticated,
    renderError = (error) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(import_jsx_runtime.Fragment, { children: JSON.stringify(error) })
  }) {
    const { isSuccess, isFetched, status, data, error } = useUser();
    if (isSuccess) {
      if (renderUnauthenticated && !data) {
        return renderUnauthenticated();
      }
      return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(import_jsx_runtime.Fragment, { children });
    }
    if (!isFetched) {
      return renderLoading();
    }
    if (status === "error") {
      return renderError(error);
    }
    return null;
  }
  return {
    useUser,
    useLogin,
    useRegister,
    useLogout,
    AuthLoader
  };
}
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {
  configureAuth
});
//# sourceMappingURL=index.js.map
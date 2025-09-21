// src/index.tsx
import {
  useMutation,
  useQuery,
  useQueryClient
} from "@tanstack/react-query";
import React from "react";
import { Fragment, jsx } from "react/jsx-runtime";
function configureAuth(config) {
  const { userFn, userKey = ["authenticated-user"], loginFn, registerFn, logoutFn } = config;
  const useUser = (options) => useQuery({
    queryKey: userKey,
    queryFn: userFn,
    ...options
  });
  const useLogin = (options) => {
    const queryClient = useQueryClient();
    const setUser = React.useCallback((data) => queryClient.setQueryData(userKey, data), [queryClient]);
    return useMutation({
      mutationFn: loginFn,
      ...options,
      onSuccess: (user, ...rest) => {
        setUser(user);
        options?.onSuccess?.(user, ...rest);
      }
    });
  };
  const useRegister = (options) => {
    const queryClient = useQueryClient();
    const setUser = React.useCallback((data) => queryClient.setQueryData(userKey, data), [queryClient]);
    return useMutation({
      mutationFn: registerFn,
      ...options,
      onSuccess: (user, ...rest) => {
        setUser(user);
        options?.onSuccess?.(user, ...rest);
      }
    });
  };
  const useLogout = (options) => {
    const queryClient = useQueryClient();
    const setUser = React.useCallback((data) => queryClient.setQueryData(userKey, data), [queryClient]);
    return useMutation({
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
    renderError = (error) => /* @__PURE__ */ jsx(Fragment, { children: JSON.stringify(error) })
  }) {
    const { isSuccess, isFetched, status, data, error } = useUser();
    if (isSuccess) {
      if (renderUnauthenticated && !data) {
        return renderUnauthenticated();
      }
      return /* @__PURE__ */ jsx(Fragment, { children });
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
export {
  configureAuth
};
//# sourceMappingURL=index.mjs.map
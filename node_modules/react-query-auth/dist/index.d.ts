import * as _tanstack_react_query from '@tanstack/react-query';
import { QueryFunction, QueryKey, MutationFunction, UseQueryOptions, UseMutationOptions } from '@tanstack/react-query';
import React from 'react';

interface ReactQueryAuthConfig<User, LoginCredentials, RegisterCredentials> {
    userFn: QueryFunction<User, QueryKey>;
    loginFn: MutationFunction<User, LoginCredentials>;
    registerFn: MutationFunction<User, RegisterCredentials>;
    logoutFn: MutationFunction<unknown, unknown>;
    userKey?: QueryKey;
}
interface AuthProviderProps {
    children: React.ReactNode;
}
declare function configureAuth<User, Error, LoginCredentials, RegisterCredentials>(config: ReactQueryAuthConfig<User, LoginCredentials, RegisterCredentials>): {
    useUser: (options?: Omit<UseQueryOptions<User, Error, User, QueryKey>, "queryKey" | "queryFn">) => _tanstack_react_query.UseQueryResult<User, Error>;
    useLogin: (options?: Omit<UseMutationOptions<User, Error, LoginCredentials>, "mutationFn">) => _tanstack_react_query.UseMutationResult<User, Error, LoginCredentials, unknown>;
    useRegister: (options?: Omit<UseMutationOptions<User, Error, RegisterCredentials>, "mutationFn">) => _tanstack_react_query.UseMutationResult<User, Error, RegisterCredentials, unknown>;
    useLogout: (options?: UseMutationOptions<unknown, Error, unknown>) => _tanstack_react_query.UseMutationResult<unknown, Error, unknown, unknown>;
    AuthLoader: ({ children, renderLoading, renderUnauthenticated, renderError, }: {
        children: React.ReactNode;
        renderLoading: () => JSX.Element;
        renderUnauthenticated?: () => JSX.Element;
        renderError?: (error: Error) => JSX.Element;
    }) => JSX.Element | null;
};

export { type AuthProviderProps, type ReactQueryAuthConfig, configureAuth };

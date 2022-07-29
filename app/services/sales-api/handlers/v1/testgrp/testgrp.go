package testgrp

import (
	"context"
	"errors"
	"math/rand"
	"net/http"

	"github.com/robsongomes/service/app/business/sys/validate"
	"github.com/robsongomes/service/foundation/web"
	"go.uber.org/zap"
)

type Handlers struct {
	Log *zap.SugaredLogger
}

func (h Handlers) Test(ctx context.Context, w http.ResponseWriter, r *http.Request) error {
	if n := rand.Intn(100); n%2 == 0 {
		return validate.NewRequestError(errors.New("untrusted error"), http.StatusInternalServerError)
	}

	if n := rand.Intn(100); n%3 == 0 {
		return validate.NewRequestError(errors.New("trusted error"), http.StatusBadRequest)
	}

	if n := rand.Intn(100); n%11 == 0 {
		panic("panic error")
	}

	status := struct {
		Status string `json:"status"`
	}{
		Status: "OK",
	}

	statusCode := http.StatusOK

	return web.Respond(ctx, w, status, statusCode)
}

import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import * as MiniZinc from 'minizinc';
import { catchError, from, Observable, of, switchMap } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class MinizincService {
  model: MiniZinc.Model | undefined;
  constructor(private http: HttpClient) { }

  initializeService(): Observable<unknown> {
    return from(MiniZinc.init({
      minizinc: 'minizinc',
      workerURL: new URL('/assets/minizinc/minizinc-worker.js?url', window.location.href),
      wasmURL: new URL('/assets/minizinc/minizinc.wasm?url', window.location.href),
      dataURL: new URL('/assets/minizinc/minizinc.data?url', window.location.href),
    })).pipe(
      catchError((err) => {
        console.error(`Something goes wrong: ${err}`);
        return of(false);
      }),
      switchMap(() => of(true))
    );
  }

  readModel(): Observable<string> {
    return this.http.get<string>('assets/models/CalDep.mzn', { responseType: 'text' as 'json' });
  }
}

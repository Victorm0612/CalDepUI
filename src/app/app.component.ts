import { Component, OnInit } from '@angular/core';
import { FormGroup, FormControl, Validators } from '@angular/forms';
import * as MiniZinc from 'minizinc';
import { minizincWorker } from 'minizinc/minizinc-worker.js';
import minizincWasm from 'minizinc/minizinc.wasm';
import minizincData from 'minizinc/minizinc.data';


@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})
export class AppComponent implements OnInit {
  title = 'cal-dep';
  form = new FormGroup({
    n: new FormControl('', Validators.required),
    min: new FormControl('', Validators.required),
    max: new FormControl('', Validators.required),
    d: new FormControl('', Validators.required),
  });

  ngOnInit() {
    (async() => await MiniZinc.init({
      workerURL: new URL('/assets/minizinc/dist/minizinc-worker.js', window.location.href),
      wasmURL: new URL('/assets/minizinc/dist/minizinc.wasm', window.location.href),
      dataURL: new URL('/assets/minizinc/dist/minizinc.data', window.location.href),
    }).then(() => {
      console.log('Ready');
    }))();
    const model = new MiniZinc.Model();
    model.addFile('test.mzn', 'var 1..3: x;');
  }

  onSubmit() {
    console.log(this.form.value);
  }
}

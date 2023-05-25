import { Component, OnInit } from '@angular/core';
import { FormGroup, FormControl, Validators } from '@angular/forms';
import * as MiniZinc from 'minizinc';
import { switchMap, take } from 'rxjs';
import { MinizincService } from './services';


@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})
export class AppComponent implements OnInit {
  private readonly STATUS_DONE = 'OPTIMAL_SOLUTION';
  model!: MiniZinc.Model;
  modelInfo: string = '';
  showCalendar = false;
  calendar: number[][] = [];
  cost!: number;
  form = new FormGroup({
    n: new FormControl('', Validators.required),
    min: new FormControl('', Validators.required),
    max: new FormControl('', Validators.required),
    d: new FormControl('', Validators.required),
  });

  constructor(
    private service: MinizincService
  ) { }

  ngOnInit() {
    this.service.initializeService()
      .pipe(
        take(1),
        switchMap(() => this.service.readModel())
      )
      .subscribe({
        next: (model) => {
          console.log('Ready');
          this.modelInfo = model;
        },
        error: (err) => {
          console.log(err);
        }
      })
  }

  downloadFile() {
    const { n, min, max, d } = this.form.value;
    const dzn = `n=${n}; Min=${min}; Max=${max}; D=${d}`;
    const file = new Blob([dzn], {type: 'text/plain'});
    const a = document.createElement("a");
    const url = URL.createObjectURL(file);
    a.href = url;
    a.download = 'DatosCalDep.dzn';
    document.body.appendChild(a);
    a.click();
    setTimeout(() => {
        document.body.removeChild(a);
        window.URL.revokeObjectURL(url);
    }, 0);
  }

  onSubmit() {
    const { n, min, max, d } = this.form.value;
    this.model = new MiniZinc.Model();
    this.model.addFile('CalDep.mzn', this.modelInfo);
    const dzn = `n=${n}; Min=${min}; Max=${max}; D=${d}`;
    this.model.addDznString(dzn);
    const solve = this.model.solve({
      options: {
        solver: 'gecode',
        'all-solutions': true
      }
    });
    solve.on('solution', solution => {
      const output = solution.output.json;
      if (output) {
        this.cost = output['u'];
        this.calendar = output['Cal'].reverse();
      }
    });
    solve.then(result => {
      if (result.status === this.STATUS_DONE) {
        this.showCalendar = true;
        console.log(this.calendar);
      }
    });
  }
}
